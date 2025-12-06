import logging
import os
from typing import Any

from dotenv import load_dotenv
from langchain_core.prompts import ChatPromptTemplate
from langchain_neo4j import Neo4jGraph
from langchain_openai import ChatOpenAI

# Configuração de Logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

load_dotenv()


class AuditService:
    """
    Serviço de Auditoria Proativa.
    Verifica se o código está em conformidade com as regras SISP indexadas no grafo.
    """

    def __init__(self):
        try:
            url = os.getenv("NEO4J_URI")
            username = os.getenv("NEO4J_USERNAME")
            password = os.getenv("NEO4J_PASSWORD")

            if not all([url, username, password]):
                raise ValueError("Credenciais do Neo4j não encontradas no .env")

            self.graph = Neo4jGraph(url=url, username=username, password=password)

            # LLM para análise
            self.llm = ChatOpenAI(
                model="gpt-4o",  # Usando modelo mais capaz para auditoria
                temperature=0,
            )

            logger.info("AuditService inicializado.")
        except Exception as e:
            logger.error(f"Erro ao inicializar AuditService: {e}")
            raise

    def get_related_rules(
        self, code_node_id: str, node_label: str = "Class"
    ) -> list[str]:
        """
        Busca os chunks de manuais (regras) conectados ao nó de código.
        """
        query = f"""
        MATCH (c:{node_label})-[r:REFERENCIA_CODIGO]-(rule:Chunk)
        WHERE elementId(c) = $id OR id(c) = $id
        RETURN rule.texto as text, r.score as score
        ORDER BY r.score DESC
        LIMIT 5
        """
        # Nota: O sentido da aresta REFERENCIA_CODIGO é Chunk -> Code.
        # Por isso usamos -(rule:Chunk) sem seta ou <-[r]-

        try:
            results = self.graph.query(query, params={"id": code_node_id})
            return [row["text"] for row in results]
        except Exception as e:
            logger.error(f"Erro ao buscar regras para {node_label} {code_node_id}: {e}")
            return []

    def audit_code_node(
        self, node_id: int, node_label: str, code_content: str, code_name: str
    ) -> dict[str, Any]:
        """
        Realiza a auditoria de um nó específico de código.
        """
        logger.info(f"Auditando {node_label}: {code_name}...")

        # 1. Buscar Regras Relacionadas
        rules = self.get_related_rules(node_id, node_label)

        if not rules:
            logger.info(
                f"Nenhuma regra SISP vinculada encontrada para {code_name}. Pulando."
            )
            return {"status": "SKIPPED", "reason": "No related rules found"}

        rules_text = "\n---\n".join(rules)

        # 2. Prompt de Auditoria
        prompt = ChatPromptTemplate.from_messages(
            [
                (
                    "system",
                    """Você é um Auditor de Qualidade de Software especializado nas normas do SISP (Sistema de Administração dos Recursos de Tecnologia da Informação).
            Sua tarefa é analisar um trecho de código e verificar se ele viola as regras fornecidas.
            
            Se houver violação, cite a regra específica e explique o problema.
            Se estiver em conformidade, diga "CONFORME".
            Se as regras fornecidas não se aplicarem ao contexto do código, diga "NÃO APLICÁVEL".
            """,
                ),
                (
                    "user",
                    """
            REGRAS SISP RELEVANTES:
            {rules}
            
            CÓDIGO PARA ANÁLISE ({type} - {name}):
            ```python
            {code}
            ```
            
            RELATÓRIO DE AUDITORIA:
            """,
                ),
            ]
        )

        chain = prompt | self.llm

        try:
            response = chain.invoke(
                {
                    "rules": rules_text,
                    "type": node_label,
                    "name": code_name,
                    "code": code_content,
                }
            )

            result = response.content

            # 3. Registrar Resultado no Grafo (Opcional: Criar nó de Issue)
            if "CONFORME" not in result and "NÃO APLICÁVEL" not in result:
                self.register_violation(node_id, node_label, result)
                return {"status": "VIOLATION", "report": result}

            return {"status": "OK", "report": result}

        except Exception as e:
            logger.error(f"Erro durante análise LLM: {e}")
            return {"status": "ERROR", "error": str(e)}

    def register_violation(self, node_id: int, node_label: str, report: str):
        """
        Cria um nó de Issue no grafo conectado ao código.
        """
        query = f"""
        MATCH (c:{node_label})
        WHERE id(c) = $id
        CREATE (i:Issue {{
            description: $report,
            created_at: datetime(),
            status: 'OPEN'
        }})
        MERGE (c)-[:HAS_ISSUE]->(i)
        """
        self.graph.query(query, params={"id": node_id, "report": report})
        logger.info(f"Violação registrada para nó {node_id}")

    def run_audit_cycle(self):
        """
        Busca códigos recentes (ou todos) e roda a auditoria.
        Por enquanto, vamos pegar uma amostra de Classes que tenham links com documentação.
        """
        # Busca classes que TEM links com documentação (para testar o RAG)
        query = """
        MATCH (c:Class)<-[:REFERENCIA_CODIGO]-(d:Chunk)
        WITH c, count(d) as rule_count
        WHERE rule_count > 0
        RETURN id(c) as id, c.name as name, c.docstring as docstring
        LIMIT 5
        """

        nodes_to_audit = self.graph.query(query)
        logger.info(f"Encontrados {len(nodes_to_audit)} candidatos para auditoria.")

        for node in nodes_to_audit:
            # Reconstrói um "conteúdo" aproximado usando docstring (já que não salvamos o source full no nó, apenas no File)
            # Idealmente, buscaríamos o source do nó :File, mas para este teste usaremos a docstring.
            code_content = f'class {node["name"]}:\n    """\n{node["docstring"]}\n    """\n    pass'

            self.audit_code_node(node["id"], "Class", code_content, node["name"])


if __name__ == "__main__":
    auditor = AuditService()
    auditor.run_audit_cycle()

import logging
import os
from typing import cast

from dotenv import load_dotenv
from langchain_community.vectorstores import Neo4jVector
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_neo4j import Neo4jGraph
from langchain_openai import ChatOpenAI, OpenAIEmbeddings
from pydantic import BaseModel, Field

# Configura o logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


class PropostaAtualizacao(BaseModel):
    """
    Modelo de dados para uma proposta de atualização de documentação.
    """

    texto_atualizado: str = Field(
        description="O novo texto para o trecho da documentação, incorporando as mudanças da RCM."  # noqa: E501
    )
    resumo_da_mudanca: str = Field(
        description="Um resumo conciso explicando o que foi alterado na documentação."
    )


class AgenteDocumentacao:
    """
    Agente autônomo para manter a documentação do sistema atualizada.
    """

    def __init__(self) -> None:
        load_dotenv()
        self.llm = ChatOpenAI(model="gpt-4-turbo", temperature=0)
        self.embeddings = OpenAIEmbeddings()
        self.graph = Neo4jGraph(
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
        )
        # Inicializa o retriever para busca vetorial nos manuais
        self.retriever = Neo4jVector.from_existing_index(
            embedding=self.embeddings,  # Correção: Usa o modelo de embeddings
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
            index_name="manual-chunks",
            text_node_property="texto",
        ).as_retriever(search_kwargs={"k": 10})

    def _buscar_rcms_para_documentar(self) -> list[dict]:
        """Busca RCMs concluídos que ainda não foram documentados."""
        logging.info("Buscando RCMs concluídos para documentar...")  # noqa: LOG015
        query = """
        MATCH (rcm:RCM)-[:ORIGINADO_DE]->(s:Solicitacao)
        WHERE toLower(rcm.status) IN ['concluído', 'entregue', 'aceite produção']
          AND (toLower(s.tipo_solicitacao) IN ['evolutivo', 'melhoria', 'corretivo'])
          AND NOT (rcm)-[:GEROU_ATUALIZACAO]->(:AtualizacaoDocumento)
        RETURN
            rcm.id AS rcm_id,
            rcm.description AS rcm_texto,
            s.title AS solicitacao_titulo
        LIMIT 5
        """
        return self.graph.query(query)

    def _gerar_proposta_atualizacao(
        self, rcm_texto: str, texto_manual_original: str
    ) -> PropostaAtualizacao:
        """Usa um LLM para gerar uma nova versão do texto do manual."""
        structured_llm = self.llm.with_structured_output(PropostaAtualizacao)
        prompt = ChatPromptTemplate.from_template(
            """Você é um Escritor Técnico Sênior. Sua tarefa é atualizar um trecho de um manual de sistema com base em uma Requisição de Mudança (RCM) que foi implementada.

            **Trecho Original do Manual:**
            {manual_original}

            **Descrição da RCM (O que mudou):**
            {rcm}

            **Instruções:**
            1.  Leia a RCM para entender a mudança (seja uma correção de bug ou uma nova funcionalidade).
            2.  Re-escreva o "Trecho Original do Manual" para refletir com precisão a mudança descrita na RCM. Mantenha o tom e o estilo do texto original.
            3.  Crie um resumo claro e conciso da alteração que você fez.
            """  # noqa: E501
        )
        chain = prompt | structured_llm
        return cast(
            "PropostaAtualizacao",
            chain.invoke({"manual_original": texto_manual_original, "rcm": rcm_texto}),
        )

    def _registrar_atualizacao(
        self, rcm_id: int, chunk_id: int, proposta: PropostaAtualizacao
    ) -> None:
        """Salva a proposta de atualização no grafo."""
        logging.info(  # noqa: LOG015
            f"Registrando atualização de documentação para o RCM ID {rcm_id}..."  # noqa: G004
        )
        query = """
        MATCH (rcm:RCM {id: $rcm_id})
        MATCH (chunk:Chunk) WHERE id(chunk) = $chunk_id
        CREATE (ad:AtualizacaoDocumento {
            texto_atualizado: $texto_atualizado,
            resumo_da_mudanca: $resumo_da_mudanca,
            data_geracao: datetime()
        })
        MERGE (rcm)-[:GEROU_ATUALIZACAO]->(ad)
        MERGE (ad)-[:ATUALIZA_CHUNK]->(chunk)
        """
        self.graph.query(
            query,
            params={
                "rcm_id": rcm_id,
                "chunk_id": chunk_id,
                "texto_atualizado": proposta.texto_atualizado,
                "resumo_da_mudanca": proposta.resumo_da_mudanca,
            },
        )

    def executar_ciclo_atualizacao(self) -> str | None:
        """Executa um ciclo completo de verificação e atualização da documentação."""
        # Verifica se os dados necessários para as análises existem
        has_rcm_data = self.graph.query("MATCH (n:RCM) RETURN n LIMIT 1")
        if not has_rcm_data:
            return (
                "📄 Dados insuficientes para o Agente de Documentação! Para manter os manuais atualizados, o agente precisa acessar as RCMs implementadas.\n"  # noqa: E501
                "   - 📂 **Arquivo**: `rcms.csv`\n"
                "     **Descrição**: Contém os dados das Requisições de Mudança (RCMs) concluídas.\n"  # noqa: E501
                "     **Colunas essenciais**: `id`, `description` (com o detalhe da mudança), `status` e `id_solicitacao`."  # noqa: E501
            )

        rcms_para_documentar = self._buscar_rcms_para_documentar()
        if not rcms_para_documentar:
            logging.info("Nenhuma nova RCM para documentar.")  # noqa: LOG015
            return None

        logging.info(f"Encontradas {len(rcms_para_documentar)} RCMs para documentar.")  # noqa: G004, LOG015
        # Esta é uma implementação simplificada. A lógica de encontrar o chunk relevante
        # seria mais complexa, envolvendo busca vetorial.
        logging.warning(  # noqa: LOG015
            "Funcionalidade de atualização de documentação em desenvolvimento."
        )
        return None

    def gerar_manual_por_topico(self, topico: str) -> str:
        """
        Busca informações sobre um tópico e gera um manual formatado em Markdown.
        """
        logging.info(f"Gerando manual para o tópico: {topico}")  # noqa: G004, LOG015

        # 1. Busca chunks de documentos relevantes usando busca vetorial
        docs_relevantes = self.retriever.invoke(topico)
        contexto = "\n\n---\n\n".join([doc.page_content for doc in docs_relevantes])

        # 2. Usa o LLM para compilar os chunks em um manual formatado
        prompt = ChatPromptTemplate.from_template(
            """Você é um Escritor Técnico e especialista em documentação de software.
            Sua tarefa é criar um manual de usuário claro e bem formatado sobre um tópico específico, usando os trechos de documentação fornecidos.

            **Tópico Solicitado:** {topico}

            **Trechos da Documentação:**
            {contexto}

            **Instruções:**
            1.  **Título:** Crie um título claro para o manual (ex: `# Manual de Usuário: Férias`).
            2.  **Introdução:** Escreva um parágrafo introdutório explicando o propósito do manual.
            3.  **Índice:** Crie um índice com links para as seções principais do documento.
            4.  **Conteúdo:** Organize os trechos fornecidos em seções lógicas e coerentes. Re-escreva e conecte as informações para que fluam como um documento único, não apenas uma lista de trechos. Use subtítulos (`##`, `###`) para cada seção.
            5.  **Formatação:** Use Markdown (negrito, listas, etc.) para melhorar a legibilidade.
            """  # noqa: E501
        )
        chain = prompt | self.llm | StrOutputParser()
        return chain.invoke({"topico": topico, "contexto": contexto})


if __name__ == "__main__":
    agente = AgenteDocumentacao()
    agente.executar_ciclo_atualizacao()

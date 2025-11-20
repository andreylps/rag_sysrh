import logging
import os
import uuid

from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph

from rag_sysrh.main import get_tools

# Configuração de Logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)

# Carregar variáveis de ambiente
load_dotenv()


def verify_reactive_agent():
    """
    Verifica se o Agente Reativo (Chat) respeita as novas labels de status.
    """
    logging.info("--- INICIANDO VERIFICAÇÃO DO AGENTE REATIVO ---")

    try:
        # Conexão direta para setup de dados
        graph = Neo4jGraph(
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
        )

        # Obter ferramentas do agente
        tools = get_tools()
        factual_tool = next(t for t in tools if t.name == "Factual_Question_Answering")
        billing_tool = next(t for t in tools if t.name == "Billing_Calculator")

        # --- TESTE 1: Status :NeedsRevision ---
        logging.info("\n--- TESTE 1: Status :NeedsRevision (Chat) ---")

        # 1. Criar RCM em Revisão
        revision_rcm_id = str(uuid.uuid4())
        revision_title = f"RCM_TEST_REVISION_{revision_rcm_id[:8]}"
        graph.query(
            """
            CREATE (rcm:RCM {id: $id, titulo: $title, status: 'Concluído'})
            SET rcm:NeedsRevision
            """,
            params={"id": revision_rcm_id, "title": revision_title},
        )
        logging.info(f"RCM de teste criada: {revision_title}")

        # 2. Perguntar sobre a RCM
        query = f"Qual o status da RCM com título '{revision_title}'?"
        logging.info(f"Pergunta: {query}")
        response = factual_tool.func(query)
        logging.info(f"Resposta do Agente: {response}")

        # 3. Verificar se menciona "EM REVISÃO"
        if "EM REVISÃO" in response or "NeedsRevision" in response:
            logging.info("✅ PASSOU: Agente identificou status 'EM REVISÃO'.")
        else:
            logging.error("❌ FALHOU: Agente não reportou status de revisão.")

        # --- TESTE 2: Status :DataInconsistency ---
        logging.info("\n--- TESTE 2: Status :DataInconsistency (Billing) ---")

        # 1. Criar RCM Inconsistente
        inconsistent_rcm_id = str(uuid.uuid4())
        inconsistent_title = f"RCM_TEST_INCONSISTENT_{inconsistent_rcm_id[:8]}"
        graph.query(
            """
            CREATE (rcm:RCM:Solicitacao {
                id: $id, 
                title: $title, 
                status: 'Concluído',
                effort: 100,
                horas_realizadas: 0
            })
            SET rcm:DataInconsistency
            """,
            params={"id": inconsistent_rcm_id, "title": inconsistent_title},
        )
        # Nota: Adicionei label :Solicitacao e props de Solicitacao (effort) pq o billing busca Solicitacao ou RCM dependendo do prompt.
        # O prompt de billing atual busca (s:Solicitacao). Vamos garantir que o nó tenha essa label.

        # Garantir custos
        graph.query("""
            MERGE (c:Custo {tipo: 'ponto_funcao'}) SET c.valor = 10
        """)

        # 2. Perguntar o custo
        query = f"Qual o custo do chamado evolutivo '{inconsistent_title}'?"  # Usando 'chamado' para ativar o prompt de billing que busca Solicitacao
        # Precisamos garantir que o prompt de billing consiga achar esse nó pelo título ou ID.
        # O prompt de billing exemplo 4 usa ID. Vamos tentar pelo ID para ser mais direto, ou ajustar a pergunta.
        # O prompt diz: "Exemplo para 'custo do chamado evolutivo 123': MATCH (s:Solicitacao) WHERE s.id = 123 ..."
        # Vamos tentar perguntar pelo ID.

        # Atualizando o ID para ser um número (string numérica) se o prompt esperar isso, ou usar o UUID.
        # O prompt usa `s.id = 123` (int) ou string. O grafo tem IDs variados.
        # Vamos usar o titulo na pergunta para facilitar o "filtro" se o LLM for esperto, ou o ID.

        query = f"Calcule o custo do chamado evolutivo com id '{inconsistent_rcm_id}'"
        logging.info(f"Pergunta: {query}")
        response = billing_tool.func(query)
        logging.info(f"Resposta do Agente: {response}")

        # 3. Verificar se menciona "DADOS INCONSISTENTES"
        if "DADOS INCONSISTENTES" in response:
            logging.info("✅ PASSOU: Agente reportou 'DADOS INCONSISTENTES'.")
        else:
            logging.error("❌ FALHOU: Agente calculou valor ou não viu inconsistência.")

        # Limpeza
        logging.info("\nLimpando dados de teste...")
        graph.query(
            "MATCH (n) WHERE n.id IN [$id1, $id2] DETACH DELETE n",
            params={"id1": revision_rcm_id, "id2": inconsistent_rcm_id},
        )
        logging.info("Limpeza concluída.")

    except Exception as e:
        logging.error(f"Erro durante a verificação: {e}")
        import traceback

        traceback.print_exc()


if __name__ == "__main__":
    verify_reactive_agent()

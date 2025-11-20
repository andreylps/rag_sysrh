import logging
import os
import uuid

from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph

from rag_sysrh.agente_planejamento_rcm import AgentePlanejamentoRCM, PlanoRCM

# Configuração de Logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)

# Carregar variáveis de ambiente
load_dotenv()


def verify_rcm_approval():
    """
    Verifica o fluxo de aprovação de RCM (Pendente -> Aprovado).
    """
    logging.info("--- INICIANDO VERIFICAÇÃO DE APROVAÇÃO DE RCM ---")

    try:
        graph = Neo4jGraph(
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
        )

        agente = AgentePlanejamentoRCM()

        # 1. Setup: Criar uma Solicitação de teste
        solicitacao_id = str(uuid.uuid4())
        graph.query(
            "CREATE (s:Solicitacao {id: $id, title: 'Solicitacao Teste Aprovação'})",
            params={"id": solicitacao_id},
        )
        logging.info(f"Solicitação de teste criada: {solicitacao_id}")

        # 2. Gerar e Salvar Plano (Pendente)
        titulo_rcm = f"RCM Teste Aprovação {uuid.uuid4()}"
        plano = PlanoRCM(
            titulo_rcm=titulo_rcm,
            objetivo_negocio="Teste de fluxo de aprovação",
            descricao_tecnica_detalhada="Teste",
            plano_de_tarefas_sugerido=["Tarefa 1"],
            criterios_de_aceite=["Critério 1"],
            riscos_mapeados=["Risco 1"],
            estimativa_pontos_funcao=10,
            prazo_dias_uteis=5,
        )

        agente.salvar_plano_rcm(plano, solicitacao_id)

        # 3. Verificar estado Pendente
        result = graph.query(
            """
            MATCH (p:PlanoRCM {titulo_rcm: $titulo})
            RETURN labels(p) as labels, p.status as status
            """,
            params={"titulo": titulo_rcm},
        )

        if not result:
            logging.error("❌ FALHOU: Plano não encontrado no grafo.")
            return

        labels = result[0]["labels"]
        status = result[0]["status"]

        if "RCM_Pendente" in labels and status == "Pendente Aprovação":
            logging.info(
                "✅ PASSOU: Plano salvo corretamente como 'Pendente Aprovação'."
            )
        else:
            logging.error(
                f"❌ FALHOU: Estado incorreto. Labels: {labels}, Status: {status}"
            )
            return

        # 4. Aprovar Plano
        agente.aprovar_plano_rcm(titulo_rcm)

        # 5. Verificar estado Aprovado
        result_aprovado = graph.query(
            """
            MATCH (p:PlanoRCM {titulo_rcm: $titulo})
            RETURN labels(p) as labels, p.status as status
            """,
            params={"titulo": titulo_rcm},
        )

        labels_aprovado = result_aprovado[0]["labels"]
        status_aprovado = result_aprovado[0]["status"]

        if (
            "RCM" in labels_aprovado
            and "RCM_Pendente" not in labels_aprovado
            and status_aprovado == "Aberto"
        ):
            logging.info(
                "✅ PASSOU: Plano aprovado corretamente (Label :RCM adicionada, :RCM_Pendente removida, Status 'Aberto')."
            )
        else:
            logging.error(
                f"❌ FALHOU: Estado de aprovação incorreto. Labels: {labels_aprovado}, Status: {status_aprovado}"
            )

        # Limpeza
        logging.info("\nLimpando dados de teste...")
        graph.query(
            "MATCH (n) WHERE n.id = $sid OR n.titulo_rcm = $titulo DETACH DELETE n",
            params={"sid": solicitacao_id, "titulo": titulo_rcm},
        )
        logging.info("Limpeza concluída.")

    except Exception as e:
        logging.error(f"Erro durante a verificação: {e}")
        import traceback

        traceback.print_exc()


if __name__ == "__main__":
    verify_rcm_approval()

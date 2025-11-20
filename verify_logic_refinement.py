import logging
import os
import uuid

from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph

from rag_sysrh.agente_faturamento import AgenteFaturamento
from rag_sysrh.agente_qualidade import AgenteQualidade, AvaliacaoRCM

# Configuração de Logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)

# Carregar variáveis de ambiente
load_dotenv()


def verify_logic_refinement():
    """
    Verifica se as mudanças na lógica de negócio (Mimetismo Humano) estão funcionando.
    """
    logging.info("--- INICIANDO VERIFICAÇÃO DE REFINAMENTO DE LÓGICA ---")

    try:
        graph = Neo4jGraph(
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
        )

        # --- TESTE 1: Agente de Qualidade (Tag :NeedsRevision) ---
        logging.info("\n--- TESTE 1: Agente de Qualidade (:NeedsRevision) ---")

        # 1. Criar RCM "Ruim" (sem ID no título)
        bad_rcm_id = str(uuid.uuid4())
        graph.query(
            """
            CREATE (rcm:RCM {id: $id, titulo: 'RCM Sem Numero', status: 'Concluído'})
            """,
            params={"id": bad_rcm_id},
        )
        logging.info(f"RCM de teste criada: {bad_rcm_id}")

        # 2. Executar registro de avaliação negativa manualmente (para isolar a lógica de escrita)
        agente_qualidade = AgenteQualidade()
        avaliacao_negativa = AvaliacaoRCM(
            conformidade=False, justificativa="Título inválido."
        )
        agente_qualidade._registrar_avaliacao_conformidade(
            bad_rcm_id, avaliacao_negativa
        )

        # 3. Verificar se a tag :NeedsRevision foi aplicada
        result = graph.query(
            "MATCH (rcm:RCM {id: $id}) RETURN labels(rcm) as labels",
            params={"id": bad_rcm_id},
        )
        labels = result[0]["labels"]
        if "NeedsRevision" in labels:
            logging.info("✅ PASSOU: RCM marcada corretamente com :NeedsRevision.")
        else:
            logging.error(
                f"❌ FALHOU: RCM não recebeu a tag :NeedsRevision. Labels: {labels}"
            )

        # --- TESTE 2: Agente de Faturamento (Tag :DataInconsistency) ---
        logging.info("\n--- TESTE 2: Agente de Faturamento (:DataInconsistency) ---")

        # 1. Criar RCM "Inconsistente" (Concluído, mas 0 horas)
        inconsistent_rcm_id = str(uuid.uuid4())
        graph.query(
            """
            CREATE (rcm:RCM {
                id: $id, 
                titulo: 'RCM Inconsistente', 
                status: 'Concluído',
                pontos_funcao: 10,
                horas_realizadas: 0
            })
            """,
            params={"id": inconsistent_rcm_id},
        )

        # Garantir que existem custos para o agente rodar
        graph.query("""
            MERGE (c1:Custo {tipo: 'ponto_funcao'}) SET c1.valor = 100
            MERGE (c2:Custo {tipo: 'hora_desenvolvimento'}) SET c2.valor = 50
        """)

        # 2. Executar ciclo de rentabilidade
        agente_faturamento = AgenteFaturamento()
        # Precisamos mockar _buscar_entregas_para_analise para retornar apenas nossa RCM de teste
        # ou confiar que a query do agente vai pegá-la. Vamos forçar a busca.

        # Hack: Sobrescrever temporariamente o método de busca para focar no teste
        original_busca = agente_faturamento._buscar_entregas_para_analise
        agente_faturamento._buscar_entregas_para_analise = lambda limit=5: [
            {"rcm_id": inconsistent_rcm_id, "pontos_funcao": 10, "horas_realizadas": 0}
        ]

        agente_faturamento.executar_ciclo_rentabilidade()

        # Restaurar método original
        agente_faturamento._buscar_entregas_para_analise = original_busca

        # 3. Verificar se a tag :DataInconsistency foi aplicada
        result = graph.query(
            "MATCH (rcm:RCM {id: $id}) RETURN labels(rcm) as labels",
            params={"id": inconsistent_rcm_id},
        )
        labels = result[0]["labels"]
        if "DataInconsistency" in labels:
            logging.info("✅ PASSOU: RCM marcada corretamente com :DataInconsistency.")
        else:
            logging.error(
                f"❌ FALHOU: RCM não recebeu a tag :DataInconsistency. Labels: {labels}"
            )

        # Limpeza
        logging.info("\nLimpando dados de teste...")
        graph.query(
            "MATCH (n:RCM) WHERE n.id IN [$id1, $id2] DETACH DELETE n",
            params={"id1": bad_rcm_id, "id2": inconsistent_rcm_id},
        )
        logging.info("Limpeza concluída.")

    except Exception as e:
        logging.error(f"Erro durante a verificação: {e}")
        import traceback

        traceback.print_exc()


if __name__ == "__main__":
    verify_logic_refinement()

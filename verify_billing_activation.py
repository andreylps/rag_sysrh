import logging
import os
import uuid

from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph

from rag_sysrh.agente_faturamento import AgenteFaturamento

# Configuração de Logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)

# Carregar variáveis de ambiente
load_dotenv()


def verify_billing_activation():
    """
    Verifica a ativação do Agente de Faturamento e o tratamento de inconsistências.
    """
    logging.info("--- INICIANDO VERIFICAÇÃO DO AGENTE DE FATURAMENTO ---")

    try:
        graph = Neo4jGraph(
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
        )

        agente = AgenteFaturamento()

        # 1. Setup: Criar Custos (se não existirem)
        graph.query("""
        MERGE (c1:Custo {tipo: 'ponto_funcao'}) SET c1.valor = 100.0
        MERGE (c2:Custo {tipo: 'hora_desenvolvimento'}) SET c2.valor = 50.0
        """)

        # 2. Setup: Criar RCM Válida
        rcm_valida_id = f"RCM-VAL-{uuid.uuid4().hex[:6]}"
        graph.query(
            """
            CREATE (r:RCM {id: $id, status: 'Concluído', pontos_funcao: 10, horas_realizadas: 20})
            """,
            params={"id": rcm_valida_id},
        )

        # 3. Setup: Criar RCM Inconsistente (0 horas)
        rcm_invalida_id = f"RCM-INV-{uuid.uuid4().hex[:6]}"
        graph.query(
            """
            CREATE (r:RCM {id: $id, status: 'Concluído', pontos_funcao: 10, horas_realizadas: 0})
            """,
            params={"id": rcm_invalida_id},
        )

        # 4. Executar Ciclo Completo
        relatorio = agente.gerar_relatorio_completo()

        # 5. Verificações

        # Verificar se a RCM válida foi analisada
        result_valida = graph.query(
            "MATCH (r:RCM {id: $id})-[:TEM_ANALISE_DE]->(ar:AnaliseRentabilidade) RETURN ar",
            params={"id": rcm_valida_id},
        )
        if result_valida:
            logging.info(f"✅ PASSOU: RCM válida {rcm_valida_id} foi analisada.")
        else:
            logging.error(f"❌ FALHOU: RCM válida {rcm_valida_id} NÃO foi analisada.")

        # Verificar se a RCM inválida foi marcada como inconsistente
        result_invalida = graph.query(
            "MATCH (r:RCM:DataInconsistency {id: $id}) RETURN r",
            params={"id": rcm_invalida_id},
        )
        if result_invalida:
            logging.info(
                f"✅ PASSOU: RCM inválida {rcm_invalida_id} marcada com :DataInconsistency."
            )
        else:
            logging.error(
                f"❌ FALHOU: RCM inválida {rcm_invalida_id} NÃO foi marcada corretamente."
            )

        # Verificar se o relatório menciona a inconsistência
        if rcm_invalida_id in relatorio.insights_historico:
            logging.info("✅ PASSOU: Relatório menciona a RCM inconsistente.")
        else:
            logging.warning(
                f"⚠️ ALERTA: Relatório pode não ter mencionado a RCM inconsistente. Texto: {relatorio.insights_historico[:100]}..."
            )

        # Limpeza
        logging.info("\nLimpando dados de teste...")
        graph.query(
            "MATCH (r:RCM {id: $id}) DETACH DELETE r", params={"id": rcm_valida_id}
        )
        graph.query(
            "MATCH (r:RCM {id: $id}) DETACH DELETE r", params={"id": rcm_invalida_id}
        )
        # Não deletamos os custos pois podem ser usados por outros testes/sistema real
        logging.info("Limpeza concluída.")

    except Exception as e:
        logging.error(f"Erro durante a verificação: {e}")
        import traceback

        traceback.print_exc()


if __name__ == "__main__":
    verify_billing_activation()

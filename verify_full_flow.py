import logging
import os
import sys
import uuid
from pathlib import Path

# Adiciona o diretório 'src' ao sys.path
SRC_PATH = Path(__file__).resolve().parent / "src"
if str(SRC_PATH) not in sys.path:
    sys.path.append(str(SRC_PATH))

from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph

from rag_sysrh.agente_planejamento_rcm import AgentePlanejamentoRCM, PlanoRCM
from rag_sysrh.connectors import GitHubMockConnector

# Configuração de Logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
load_dotenv()


def verify_full_flow():
    """
    Verifica o fluxo completo supervisionado:
    1. Criação de Plano (Pendente)
    2. Tentativa de Exportação (Deve Falhar)
    3. Aprovação
    4. Exportação (Deve Sucesso)
    """
    logging.info("--- INICIANDO VERIFICAÇÃO DO FLUXO SUPERVISIONADO ---")

    try:
        graph = Neo4jGraph(
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
        )

        agente = AgentePlanejamentoRCM()
        connector = GitHubMockConnector(
            mock_file_path="data/external_system/test_full_flow_mock.json"
        )

        # 1. Setup: Criar Solicitação Dummy
        solicitacao_id = f"SOL-{uuid.uuid4().hex[:6]}"
        graph.query(
            "CREATE (s:Solicitacao {id: $id, title: 'Teste Fluxo'})",
            params={"id": solicitacao_id},
        )

        # 2. Gerar Plano (Simulado)
        titulo_rcm = f"RCM Teste Fluxo {uuid.uuid4().hex[:4]}"
        plano = PlanoRCM(
            titulo_rcm=titulo_rcm,
            objetivo_negocio="Teste de automação",
            descricao_tecnica_detalhada="Teste",
            plano_de_tarefas_sugerido=["Tarefa 1"],
            criterios_de_aceite=["Critério 1"],
            riscos_mapeados=[],
            estimativa_pontos_funcao=1,
            prazo_dias_uteis=1,
        )

        agente.salvar_plano_rcm(plano, solicitacao_id)

        # Recuperar ID do plano criado (que é um nó :PlanoRCM:RCM_Pendente)
        # O método salvar_plano_rcm gera um ID interno, mas não retorna. Vamos buscar pelo título.
        result = graph.query(
            "MATCH (p:PlanoRCM {titulo_rcm: $titulo}) RETURN p.id as id",
            params={"titulo": titulo_rcm},
        )
        rcm_pendente_id = result[0]["id"]
        logging.info(f"Plano criado com ID: {rcm_pendente_id}")

        # 3. TESTE DE SEGURANÇA: Tentar exportar SEM aprovar
        # O método exportar_para_externo busca por label :RCM. O nó atual tem :PlanoRCM:RCM_Pendente.
        # Se a query do exportar exigir :RCM, deve falhar (retornar None).
        # Vamos verificar a query no agente: "MATCH (rcm:RCM {id: $id})..."
        # Como o nó pendente NÃO tem a label :RCM (tem :PlanoRCM), a query não deve encontrar nada.

        logging.info("Tentando exportar RCM Pendente (Deve falhar)...")
        ext_id_fail = agente.exportar_para_externo(rcm_pendente_id, connector)

        if ext_id_fail is None:
            logging.info("✅ PASSOU: Exportação bloqueada para RCM não aprovada.")
        else:
            logging.error(f"❌ FALHOU: RCM Pendente foi exportada! ID: {ext_id_fail}")
            return

        # 4. Aprovar RCM
        logging.info("Aprovando RCM...")
        rcm_aprovada_id = agente.aprovar_plano_rcm(titulo_rcm)

        if rcm_aprovada_id != rcm_pendente_id:
            logging.warning(
                f"IDs diferem após aprovação? Pendente: {rcm_pendente_id}, Aprovada: {rcm_aprovada_id}"
            )

        # 5. Exportar RCM Aprovada
        logging.info("Tentando exportar RCM Aprovada (Deve funcionar)...")
        ext_id_success = agente.exportar_para_externo(rcm_aprovada_id, connector)

        if ext_id_success:
            logging.info(
                f"✅ PASSOU: RCM Aprovada exportada com sucesso. External ID: {ext_id_success}"
            )
        else:
            logging.error("❌ FALHOU: Não foi possível exportar a RCM Aprovada.")

        # Limpeza
        logging.info("Limpando dados de teste...")
        graph.query(
            "MATCH (s:Solicitacao {id: $id}) DETACH DELETE s",
            params={"id": solicitacao_id},
        )
        graph.query(
            "MATCH (r {titulo_rcm: $titulo}) DETACH DELETE r",
            params={"titulo": titulo_rcm},
        )
        if os.path.exists("data/external_system/test_full_flow_mock.json"):
            os.remove("data/external_system/test_full_flow_mock.json")

    except Exception as e:
        logging.error(f"Erro durante a verificação: {e}")
        import traceback

        traceback.print_exc()


if __name__ == "__main__":
    verify_full_flow()

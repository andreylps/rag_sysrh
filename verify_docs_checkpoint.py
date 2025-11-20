import logging
import os
import uuid

from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph

from rag_sysrh.agente_documentacao import AgenteDocumentacao, PropostaAtualizacao

# Configuração de Logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)

# Carregar variáveis de ambiente
load_dotenv()


def verify_docs_checkpoint():
    """
    Verifica o fluxo de aprovação de documentação (Pendente -> Aprovado).
    """
    logging.info("--- INICIANDO VERIFICAÇÃO DE CHECKPOINT DE DOCUMENTAÇÃO ---")

    try:
        graph = Neo4jGraph(
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
        )

        agente = AgenteDocumentacao()

        # 1. Setup: Criar RCM e Chunk de teste
        rcm_id = str(uuid.uuid4())
        chunk_id = (
            999999  # ID fictício para o chunk (precisa existir ou criamos um nó dummy)
        )

        # Criar nó Chunk dummy para o teste
        graph.query(
            "CREATE (c:Chunk {id: $cid, texto: 'Texto original'})",
            params={"cid": chunk_id},
        )
        # Obter o ID interno do nó criado
        result_chunk = graph.query(
            "MATCH (c:Chunk {id: $cid}) RETURN id(c) as internal_id",
            params={"cid": chunk_id},
        )
        internal_chunk_id = result_chunk[0]["internal_id"]

        # Criar RCM dummy
        graph.query(
            "CREATE (r:RCM {id: $rid, titulo: 'RCM Doc Test'})", params={"rid": rcm_id}
        )

        # 2. Registrar Atualização (Pendente)
        proposta = PropostaAtualizacao(
            texto_atualizado="Texto atualizado com sucesso.",
            resumo_da_mudanca="Mudança de teste.",
        )

        agente._registrar_atualizacao(rcm_id, internal_chunk_id, proposta)

        # 3. Verificar se está na lista de pendentes
        pendentes = agente.listar_atualizacoes_pendentes()
        atualizacao_encontrada = None
        for item in pendentes:
            if item["rcm_id"] == rcm_id:
                atualizacao_encontrada = item
                break

        if atualizacao_encontrada:
            logging.info("✅ PASSOU: Atualização encontrada na lista de pendentes.")
        else:
            logging.error("❌ FALHOU: Atualização não apareceu na lista de pendentes.")
            return

        # 4. Aprovar Atualização
        atualizacao_id = atualizacao_encontrada["id"]
        sucesso = agente.aprovar_atualizacao(atualizacao_id)

        if sucesso:
            logging.info("✅ PASSOU: Método de aprovação retornou sucesso.")
        else:
            logging.error("❌ FALHOU: Método de aprovação falhou.")

        # 5. Verificar status final no grafo
        result_status = graph.query(
            "MATCH (ad:AtualizacaoDocumento {id: $id}) RETURN ad.status as status",
            params={"id": atualizacao_id},
        )

        if result_status and result_status[0]["status"] == "Aprovado":
            logging.info("✅ PASSOU: Status final no grafo é 'Aprovado'.")
        else:
            logging.error(f"❌ FALHOU: Status final incorreto: {result_status}")

        # Limpeza
        logging.info("\nLimpando dados de teste...")
        graph.query(
            """
            MATCH (r:RCM {id: $rid}) DETACH DELETE r
            """,
            params={"rid": rcm_id},
        )
        graph.query(
            """
            MATCH (c:Chunk) WHERE id(c) = $cid DETACH DELETE c
            """,
            params={"cid": internal_chunk_id},
        )
        graph.query(
            """
            MATCH (ad:AtualizacaoDocumento {id: $aid}) DETACH DELETE ad
            """,
            params={"aid": atualizacao_id},
        )
        logging.info("Limpeza concluída.")

    except Exception as e:
        logging.error(f"Erro durante a verificação: {e}")
        import traceback

        traceback.print_exc()


if __name__ == "__main__":
    verify_docs_checkpoint()

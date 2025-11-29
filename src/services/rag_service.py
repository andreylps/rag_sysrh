import logging

from src.rag_sysrh.neo4j_connection import get_vector_store

# Configuração de Logging
logger = logging.getLogger(__name__)


def query_technical_knowledge_base(query: str, k: int = 4) -> str:
    """
    Consulta a base de conhecimento técnica (Vector Store) por similaridade.

    Args:
        query (str): A pergunta ou termo de busca técnica.
        k (int): Número de documentos a recuperar. Default é 4.

    Returns:
        str: Uma string formatada contendo os trechos de código/documentação mais relevantes.
    """
    try:
        # Obtém a conexão com o Vector Store
        vector_store = get_vector_store()

        # Realiza a busca por similaridade
        results = vector_store.similarity_search(query, k=k)

        if not results:
            return (
                "Nenhum documento relevante encontrado na base de conhecimento técnica."
            )

        # Formata os resultados
        formatted_results = []
        for i, doc in enumerate(results, 1):
            source = doc.metadata.get("source", "Desconhecido")
            content = doc.page_content
            formatted_results.append(
                f"--- Documento {i} (Fonte: {source}) ---\n{content}\n"
            )

        return "\n".join(formatted_results)

    except Exception as e:
        error_msg = f"Erro ao consultar base de conhecimento técnica: {str(e)}"
        logger.error(error_msg)
        return error_msg

import logging
from typing import Any, Dict

from src.rag_sysrh.neo4j_connection import get_graph

logger = logging.getLogger(__name__)


def get_dashboard_stats() -> Dict[str, Any]:
    """
    Executa queries Cypher para obter estatísticas do dashboard.
    Retorna um dicionário com métricas consolidadas.
    """
    graph = get_graph()

    stats = {
        "total_documents": 0,
        "total_chunks": 0,
        "documents_by_type": [],
        "recent_documents": [],
    }

    try:
        # 1. Total de Documentos (contando origens distintas)
        # Assumindo que cada Chunk tem uma propriedade 'source' com o caminho do arquivo
        query_docs = """
        MATCH (c:Chunk)
        RETURN count(DISTINCT c.source) as total_docs
        """
        result_docs = graph.query(query_docs)
        if result_docs:
            stats["total_documents"] = result_docs[0]["total_docs"]

        # 2. Total de Chunks
        query_chunks = """
        MATCH (c:Chunk)
        RETURN count(c) as total_chunks
        """
        result_chunks = graph.query(query_chunks)
        if result_chunks:
            stats["total_chunks"] = result_chunks[0]["total_chunks"]

        # 3. Documentos por Tipo (extensão)
        # Extrai a extensão do arquivo da propriedade source
        # Melhor fazer o split no Python para garantir
        query_by_type = """
        MATCH (c:Chunk)
        RETURN DISTINCT c.source as filename
        """
        result_by_type = graph.query(query_by_type)

        import os
        from collections import Counter

        extensions = []
        for row in result_by_type:
            filename = row["filename"]
            if filename:
                # Tenta extrair extensão
                _, ext = os.path.splitext(filename)
                if ext:
                    extensions.append(ext.upper().replace(".", ""))
                else:
                    extensions.append("DESCONHECIDO")
            else:
                extensions.append("DESCONHECIDO")

        # Conta ocorrências
        ext_counts = Counter(extensions)
        # Formata para lista de listas [["DOCX", 10], ["PDF", 5]]
        stats["documents_by_type"] = [[k, v] for k, v in ext_counts.most_common()]

        # 4. Documentos Recentes (simulado, pois Chunk pode não ter data de ingestão explícita ainda)
        # Se não tiver data, retornamos apenas os nomes distintos limitados
        query_recent = """
        MATCH (c:Chunk)
        RETURN DISTINCT c.source as filename
        LIMIT 5
        """
        result_recent = graph.query(query_recent)
        # Limpa o caminho, mantendo apenas o nome do arquivo
        stats["recent_documents"] = [
            os.path.basename(r["filename"]) for r in result_recent if r["filename"]
        ]

    except Exception as e:
        logger.error(f"Erro ao buscar estatísticas de BI: {e}")
        # Não falha a requisição inteira, retorna o que conseguiu ou zeros

    return stats

import logging
import os

from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph, Neo4jVector
from langchain_openai import OpenAIEmbeddings

# Configuração de Logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

load_dotenv()


class DocCodeLinker:
    """
    Estabelece relacionamentos semânticos entre a documentação (Chunks) e o código (Classes/Functions)
    usando similaridade vetorial.
    """

    def __init__(self):
        self.embeddings = OpenAIEmbeddings()

        try:
            url = os.getenv("NEO4J_URI")
            username = os.getenv("NEO4J_USERNAME")
            password = os.getenv("NEO4J_PASSWORD")

            if not all([url, username, password]):
                raise ValueError("Credenciais do Neo4j não encontradas no .env")

            self.graph = Neo4jGraph(url=url, username=username, password=password)

            # Inicializa vector stores para busca
            self.code_class_store = Neo4jVector.from_existing_index(
                embedding=self.embeddings,
                url=url,
                username=username,
                password=password,
                index_name="code_class_index",
                text_node_property="docstring",  # Usamos docstring como texto principal para busca
            )

            self.code_function_store = Neo4jVector.from_existing_index(
                embedding=self.embeddings,
                url=url,
                username=username,
                password=password,
                index_name="code_function_index",
                text_node_property="docstring",
            )

            logger.info("Conexão com Neo4j estabelecida para DocCodeLinker.")
        except Exception as e:
            logger.error(
                f"Falha ao conectar ao Neo4j ou inicializar Vector Stores: {e}"
            )
            raise

    def link_by_similarity(self, threshold: float = 0.75):
        """
        Percorre todos os chunks de documentação e busca códigos similares para criar links.
        """
        logger.info(
            f"Iniciando linkagem de documentação e código (Threshold: {threshold})..."
        )

        # Busca todos os chunks que ainda não têm link com código (opcional: ou reprocessa tudo)
        # Para simplificar, vamos processar chunks de manuais técnicos
        query_chunks = """
        MATCH (c:Chunk)
        RETURN c.texto AS texto, id(c) AS id
        """
        chunks = self.graph.query(query_chunks)

        logger.info(f"Processando {len(chunks)} chunks de documentação...")

        links_created = 0

        for chunk in chunks:
            chunk_text = chunk["texto"]
            chunk_id = chunk["id"]

            # 1. Busca Classes Similares
            try:
                # O método similarity_search_with_score retorna documentos e scores
                # Mas como configuramos o store com from_existing_index, ele busca no índice
                results_class = self.code_class_store.similarity_search_with_score(
                    chunk_text, k=3
                )

                for doc, score in results_class:
                    if score >= threshold:
                        # O metadata do documento retornado pelo Neo4jVector deve conter propriedades do nó
                        # Precisamos identificar o nó de código. O Neo4jVector geralmente retorna o conteúdo.
                        # Uma abordagem mais direta via Cypher pode ser melhor se o wrapper limitar o acesso ao ID.

                        # Vamos usar uma query Cypher direta para criar o link se encontrarmos o match
                        # Mas aqui já temos o 'doc' que é uma representação.
                        # Vamos assumir que o 'source' ou 'name' está no metadata.

                        # Alternativa: Usar o próprio embedding do chunk para buscar via Cypher
                        pass
            except Exception as e:
                logger.warning(f"Erro ao buscar classes para chunk {chunk_id}: {e}")

        # Abordagem Otimizada via Cypher (Mais rápida e robusta que iterar no Python)
        # Calculamos a similaridade diretamente no banco

        logger.info("Executando linkagem em massa via Cypher (Classes)...")
        query_link_classes = """
        MATCH (c:Chunk)
        WHERE c.embedding IS NOT NULL
        CALL db.index.vector.queryNodes('code_class_index', 3, c.embedding)
        YIELD node AS cls, score
        WHERE score >= $threshold
        MERGE (c)-[r:REFERENCIA_CODIGO]->(cls)
        SET r.score = score, r.tipo = 'Class'
        RETURN count(r) as links
        """
        result_cls = self.graph.query(
            query_link_classes, params={"threshold": threshold}
        )
        links_created += result_cls[0]["links"]

        logger.info("Executando linkagem em massa via Cypher (Funções)...")
        query_link_funcs = """
        MATCH (c:Chunk)
        WHERE c.embedding IS NOT NULL
        CALL db.index.vector.queryNodes('code_function_index', 3, c.embedding)
        YIELD node AS fn, score
        WHERE score >= $threshold
        MERGE (c)-[r:REFERENCIA_CODIGO]->(fn)
        SET r.score = score, r.tipo = 'Function'
        RETURN count(r) as links
        """
        result_fn = self.graph.query(query_link_funcs, params={"threshold": threshold})
        links_created += result_fn[0]["links"]

        logger.info(f"Linkagem concluída. Total de links criados: {links_created}")


if __name__ == "__main__":
    linker = DocCodeLinker()
    linker.link_by_similarity(threshold=0.75)

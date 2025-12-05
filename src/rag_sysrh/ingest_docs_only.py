import logging
import os
from pathlib import Path

from dotenv import load_dotenv
from langchain_community.document_loaders import (
    Docx2txtLoader,
    PyPDFLoader,
    UnstructuredExcelLoader,
)
from langchain_neo4j import Neo4jGraph
from langchain_openai import OpenAIEmbeddings
from langchain_text_splitters import RecursiveCharacterTextSplitter

# Configuração de Logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

load_dotenv()


class DocsOnlyIngestion:
    def __init__(self, data_directory: str):
        self.data_directory = data_directory
        self.embeddings = OpenAIEmbeddings()

        try:
            url = os.getenv("NEO4J_URI")
            username = os.getenv("NEO4J_USERNAME")
            password = os.getenv("NEO4J_PASSWORD")

            if not all([url, username, password]):
                raise ValueError("Credenciais do Neo4j não encontradas no .env")

            self.graph = Neo4jGraph(url=url, username=username, password=password)
            logger.info("Conexão com Neo4j estabelecida.")
        except Exception as e:
            logger.error(f"Falha ao conectar ao Neo4j: {e}")
            raise

    def run(self):
        logger.info(
            "Iniciando ingestão APENAS de documentos (Modo Econômico & Iterativo)..."
        )

        data_dir_abs_path = Path(self.data_directory).resolve()

        # Ensure vector index exists
        self.graph.query("""
            CREATE VECTOR INDEX `manual-chunks` IF NOT EXISTS
            FOR (c:Chunk) ON (c.embedding)
            OPTIONS { indexConfig: {
                `vector.dimensions`: 1536,
                `vector.similarity_function`: 'cosine'
            }}
        """)

        # Count total files
        total_files = 0
        for root, _, files in os.walk(data_dir_abs_path):
            for filename in files:
                if filename.lower().endswith((".pdf", ".docx", ".xlsx")):
                    total_files += 1

        logger.info(f"Total de arquivos para processar: {total_files}")

        processed_files = 0
        skipped_chunks = 0
        generated_embeddings = 0

        text_splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000, chunk_overlap=200
        )

        for root, _, files in os.walk(data_dir_abs_path):
            for filename in files:
                if not filename.lower().endswith((".pdf", ".docx", ".xlsx")):
                    continue

                filepath = os.path.join(root, filename)
                try:
                    documents = []
                    if filename.endswith(".pdf"):
                        documents = PyPDFLoader(filepath).load()
                    elif filename.endswith(".docx"):
                        documents = Docx2txtLoader(filepath).load()
                    elif filename.endswith(".xlsx"):
                        documents = UnstructuredExcelLoader(
                            filepath, mode="elements"
                        ).load()

                    if not documents:
                        continue

                    chunks = text_splitter.split_documents(documents)

                    for chunk in chunks:
                        source_doc = chunk.metadata.get("source", filename).split(
                            os.sep
                        )[-1]
                        page = chunk.metadata.get("page", 0)
                        text = chunk.page_content

                        # CHECK: Does this chunk already exist with an embedding?
                        # We use the text content as the key.
                        existing = self.graph.query(
                            "MATCH (c:Chunk {texto: $texto}) WHERE c.embedding IS NOT NULL RETURN count(c) as count",
                            params={"texto": text},
                        )

                        if existing[0]["count"] > 0:
                            # Link to manual but don't regenerate embedding
                            self.graph.query(
                                """
                                MERGE (m:Manual {nome: $source_doc})
                                MERGE (c:Chunk {texto: $texto})
                                SET c.pagina = $page
                                MERGE (c)-[:PARTE_DE]->(m)
                                """,
                                params={
                                    "source_doc": source_doc,
                                    "texto": text,
                                    "page": page,
                                },
                            )
                            skipped_chunks += 1
                        else:
                            # Generate embedding
                            embedding = self.embeddings.embed_query(text)
                            generated_embeddings += 1

                            self.graph.query(
                                """
                                MERGE (m:Manual {nome: $source_doc})
                                MERGE (c:Chunk {texto: $texto})
                                SET c.pagina = $page, c.embedding = $embedding
                                MERGE (c)-[:PARTE_DE]->(m)
                                """,
                                params={
                                    "source_doc": source_doc,
                                    "texto": text,
                                    "page": page,
                                    "embedding": embedding,
                                },
                            )

                    processed_files += 1
                    if processed_files % 5 == 0:
                        logger.info(
                            f"Progresso: {processed_files}/{total_files} arquivos. (Embeddings gerados: {generated_embeddings}, Reutilizados: {skipped_chunks})"
                        )

                except Exception as e:
                    logger.error(f"Erro ao processar {filename}: {e}")

        logger.info(
            f"Concluído! Total Embeddings Gerados: {generated_embeddings}. Total Reutilizados: {skipped_chunks}."
        )


if __name__ == "__main__":
    project_root = os.path.join(os.path.dirname(__file__), "..", "..")
    data_path = os.path.join(project_root, "data")

    ingestor = DocsOnlyIngestion(data_path)
    ingestor.run()

# src/rag_sysrh/ingestion_service.py

import logging
import os
from pathlib import Path

# --- IMPORTS CORRIGIDOS ---
from dotenv import load_dotenv
from langchain_community.document_loaders import Docx2txtLoader, PyPDFLoader

# Importamos a classe Neo4jVector diretamente para usar o método from_documents
from langchain_openai import OpenAIEmbeddings
from langchain_text_splitters import RecursiveCharacterTextSplitter

# Carrega variáveis de ambiente para ter acesso às credenciais
load_dotenv()

logger = logging.getLogger(__name__)


def ingest_uploaded_file(file_path: str) -> int:
    """
    Lê um arquivo PDF ou DOCX, divide em chunks e ingere no Neo4j.
    Cria nós :Manual e :Chunk, e gera embeddings.
    Retorna o número de chunks processados.
    """
    file_ext = os.path.splitext(file_path)[1].lower()

    if file_ext == ".pdf":
        loader = PyPDFLoader(file_path)
    elif file_ext == ".docx":
        loader = Docx2txtLoader(file_path)
    elif file_ext == ".txt":
        from langchain_community.document_loaders import TextLoader

        loader = TextLoader(file_path)
    else:
        # Ignora arquivos não suportados silenciosamente ou com log
        logger.warning(f"Formato de arquivo não suportado para ingestão: {file_ext}")
        return 0

    try:
        documents = loader.load()
    except Exception as e:
        logger.error(f"Erro ao ler arquivo {file_path}: {e}")
        return 0

    # Divide os documentos em chunks
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=1000,
        chunk_overlap=200,
        length_function=len,
    )
    chunks = text_splitter.split_documents(documents)

    if not chunks:
        logger.warning(f"Nenhum chunk gerado para o arquivo: {file_path}")
        return 0

    try:
        # Obtém credenciais do ambiente
        url = os.getenv("NEO4J_URI")
        username = os.getenv("NEO4J_USERNAME")
        password = os.getenv("NEO4J_PASSWORD")
        openai_api_key = os.getenv("OPENAI_API_KEY")

        if not all([url, username, password, openai_api_key]):
            raise ValueError(
                "Credenciais do Neo4j ou OpenAI não encontradas no arquivo .env"
            )

        # Conecta ao Neo4j
        from langchain_neo4j import Neo4jGraph

        graph = Neo4jGraph(url=url, username=username, password=password)

        # Embeddings
        embeddings = OpenAIEmbeddings(openai_api_key=openai_api_key)

        source_doc = os.path.basename(file_path)

        # Remove chunks antigos desse arquivo para evitar duplicidade (update)
        graph.query(
            "MATCH (m:Manual {nome: $nome})-[r]-() DELETE r DELETE m",
            params={"nome": source_doc},
        )
        # Nota: A query acima deleta o manual e seus relacionamentos.
        # Para limpar os chunks órfãos, seria ideal:
        # MATCH (c:Chunk)-[:PARTE_DE]->(m:Manual {nome: $nome}) DETACH DELETE c DETACH DELETE m
        graph.query(
            """
            MATCH (c:Chunk)-[:PARTE_DE]->(m:Manual {nome: $nome})
            DETACH DELETE c, m
        """,
            params={"nome": source_doc},
        )

        logger.info(f"Ingerindo {len(chunks)} chunks de '{source_doc}'...")

        for chunk in chunks:
            page = chunk.metadata.get("page", 0)
            embedding = embeddings.embed_query(chunk.page_content)

            graph.query(
                """
                MERGE (m:Manual {nome: $source_doc})
                CREATE (c:Chunk {texto: $texto, pagina: $page})
                SET c.embedding = $embedding
                MERGE (c)-[:PARTE_DE]->(m)
                """,
                params={
                    "source_doc": source_doc,
                    "texto": chunk.page_content,
                    "page": page,
                    "embedding": embedding,
                },
            )

        # Garante que o índice existe (idempotente)
        graph.query("""
            CREATE VECTOR INDEX `manual-chunks` IF NOT EXISTS
            FOR (c:Chunk) ON (c.embedding)
            OPTIONS { indexConfig: {
                `vector.dimensions`: 1536,
                `vector.similarity_function`: 'cosine'
            }}
        """)

        logger.info(f"Sucesso: '{source_doc}' ingerido/atualizado no Neo4j.")

    except Exception as e:
        logger.error(f"Falha crítica ao ingerir '{file_path}': {e}")
        raise e

    return len(chunks)


# ... (O resto do arquivo com list_available_manuals e run_selective_ingestion pode permanecer igual)
def list_available_manuals() -> list[str]:
    """
    Lista todos os arquivos na pasta data/manuais.
    """
    # Caminho absoluto para data/manuais
    manuals_dir = Path(__file__).resolve().parent.parent.parent / "data" / "manuais"

    if not manuals_dir.exists():
        return []

    manuals = []
    for root, _, files in os.walk(manuals_dir):
        for file in files:
            if file.lower().endswith((".pdf", ".docx", ".txt")):
                # Retorna caminho relativo a data/manuais para exibição
                rel_path = os.path.relpath(os.path.join(root, file), manuals_dir)
                manuals.append(rel_path)

    return sorted(manuals)


def run_selective_ingestion(
    selected_manuals: list[str], ingest_system_data: bool = True
) -> dict:
    # (Esta função é a de sincronização em massa, se ela funcionava, pode manter o código original dela aqui.
    #  O foco da correção foi na função ingest_uploaded_file acima.)
    # ... [Código da sua função run_selective_ingestion original] ...
    """
    Executa a ingestão seletiva.
    """
    from src.rag_sysrh.data_ingestion import DataIngestion

    logger = logging.getLogger(__name__)

    try:
        # Instancia a classe de ingestão legado
        ingestion = DataIngestion(
            data_directory="data",
            structured_data_path="data/solicitacoes.csv",
            rcm_data_path="data/rcms_01.csv",
        )

        # Limpa o banco sempre para garantir consistência (conforme aprovado)
        logger.info("Limpando banco de dados para sincronização...")
        ingestion.graph.query("MATCH (n) DETACH DELETE n")

        # 1. Ingestão de Dados do Sistema (Obrigatório/Padrão)
        if ingest_system_data:
            logger.info("Ingerindo dados do sistema (Solicitações, RCMs, Custos)...")
            ingestion._load_and_ingest_structured_data()
            ingestion._load_and_ingest_cost_data()
            ingestion._load_and_ingest_rcm_data()
            ingestion._load_and_ingest_test_cases()

        # 2. Ingestão de Manuais Selecionados
        if selected_manuals:
            logger.info(f"Ingerindo {len(selected_manuals)} manuais selecionados...")

            # Recria o índice vetorial antes de inserir chunks
            ingestion.graph.query("""
                CREATE VECTOR INDEX `manual-chunks` IF NOT EXISTS
                FOR (c:Chunk) ON (c.embedding)
                OPTIONS { indexConfig: {
                    `vector.dimensions`: 1536,
                    `vector.similarity_function`: 'cosine'
                }}
            """)

            base_path = (
                Path(__file__).resolve().parent.parent.parent / "data" / "manuais"
            )

            for manual_rel_path in selected_manuals:
                full_path = base_path / manual_rel_path
                if full_path.exists():
                    # Reutiliza a lógica de carga de documento único
                    # Hack: Ajusta o single_manual_path temporariamente ou chama método privado
                    # Vamos usar a lógica de _load_documents adaptada

                    # Carrega
                    docs = []
                    if str(full_path).endswith(".pdf"):
                        docs = PyPDFLoader(str(full_path)).load()
                    elif str(full_path).endswith(".docx"):
                        docs = Docx2txtLoader(str(full_path)).load()

                    if not docs:
                        continue

                    # Split
                    text_splitter = RecursiveCharacterTextSplitter(
                        chunk_size=1000, chunk_overlap=200
                    )
                    chunks = text_splitter.split_documents(docs)

                    # Ingest
                    for chunk in chunks:
                        source_doc = os.path.basename(str(full_path))
                        page = chunk.metadata.get("page", 0)

                        # Gera embedding
                        embedding = ingestion.embeddings.embed_query(chunk.page_content)

                        ingestion.graph.query(
                            """
                            MERGE (m:Manual {nome: $source_doc})
                            CREATE (c:Chunk {texto: $texto, pagina: $page})
                            SET c.embedding = $embedding
                            MERGE (c)-[:PARTE_DE]->(m)
                            """,
                            params={
                                "source_doc": source_doc,
                                "texto": chunk.page_content,
                                "page": page,
                                "embedding": embedding,
                            },
                        )
                else:
                    logger.warning(f"Manual não encontrado: {full_path}")

        return {"status": "success", "message": "Ingestão concluída com sucesso."}

    except Exception as e:
        logger.error(f"Erro na ingestão seletiva: {e}")
        raise e

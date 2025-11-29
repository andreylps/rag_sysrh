import os

from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph, Neo4jVector
from langchain_openai import OpenAIEmbeddings

# Carrega variáveis de ambiente (.env)
load_dotenv()


def get_vector_store():
    """
    Retorna uma instância configurada do Neo4jVector.
    Lê as credenciais das variáveis de ambiente.
    """
    url = os.getenv("NEO4J_URI")
    username = os.getenv("NEO4J_USERNAME")
    password = os.getenv("NEO4J_PASSWORD")
    openai_api_key = os.getenv("OPENAI_API_KEY")

    if not all([url, username, password, openai_api_key]):
        raise ValueError(
            "Credenciais do Neo4j ou OpenAI não encontradas no arquivo .env"
        )

    # Inicializa os embeddings
    embeddings = OpenAIEmbeddings(openai_api_key=openai_api_key)

    # Conecta ao vector store
    vector_store = Neo4jVector.from_existing_graph(
        embedding=embeddings,
        url=url,
        username=username,
        password=password,
        index_name="knowledge_index",  # Nome do índice no Neo4j
        node_label="Chunk",  # Label dos nós de texto
        text_node_properties=["text"],  # Propriedade que contém o texto
        embedding_node_property="embedding",  # Propriedade do vetor
    )

    return vector_store


_graph_instance = None


def get_graph() -> Neo4jGraph:
    """
    Retorna uma instância configurada do Neo4jGraph para execução de Cypher.
    Usa Singleton para evitar recarregar o schema a cada chamada.
    """
    global _graph_instance

    if _graph_instance is not None:
        return _graph_instance

    url = os.getenv("NEO4J_URI")
    username = os.getenv("NEO4J_USERNAME")
    password = os.getenv("NEO4J_PASSWORD")

    if not all([url, username, password]):
        raise ValueError("Credenciais do Neo4j não encontradas no arquivo .env")

    _graph_instance = Neo4jGraph(url=url, username=username, password=password)
    return _graph_instance

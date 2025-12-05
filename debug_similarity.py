import os

from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph

load_dotenv()

try:
    url = os.getenv("NEO4J_URI")
    username = os.getenv("NEO4J_USERNAME")
    password = os.getenv("NEO4J_PASSWORD")

    graph = Neo4jGraph(url=url, username=username, password=password)

    # Pick one chunk with embedding
    chunk = graph.query(
        "MATCH (c:Chunk) WHERE c.embedding IS NOT NULL RETURN c.texto as text, c.embedding as vector LIMIT 1"
    )

    if not chunk:
        print("No chunks with embeddings found!")
        exit()

    vector = chunk[0]["vector"]
    text = chunk[0]["text"][:100]
    print(f"Chunk Text: {text}...")

    # Query similarity against Classes manually
    query = """
    MATCH (c:Class)
    WHERE c.embedding IS NOT NULL
    WITH c, vector.similarity.cosine(c.embedding, $vector) AS score
    RETURN c.name, score
    ORDER BY score DESC
    LIMIT 5
    """

    result = graph.query(query, params={"vector": vector})

    print("\nTop 5 Similar Classes:")
    for row in result:
        print(f"{row['c.name']}: {row['score']}")

except Exception as e:
    print(f"Error: {e}")

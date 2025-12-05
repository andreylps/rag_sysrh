import os

from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph

load_dotenv()

try:
    url = os.getenv("NEO4J_URI")
    username = os.getenv("NEO4J_USERNAME")
    password = os.getenv("NEO4J_PASSWORD")

    graph = Neo4jGraph(url=url, username=username, password=password)

    # Check for nodes with embeddings
    result = graph.query("""
    MATCH (n) 
    WHERE (n:Class OR n:Function OR n:Chunk) AND n.embedding IS NOT NULL
    RETURN labels(n) as label, count(n) as count
    """)

    print("Nodes with embeddings:")
    for row in result:
        print(f"{row['label']}: {row['count']}")

    # Check for nodes WITHOUT embeddings
    result_missing = graph.query("""
    MATCH (n) 
    WHERE (n:Class OR n:Function OR n:Chunk) AND n.embedding IS NULL
    RETURN labels(n) as label, count(n) as count
    """)

    print("\nNodes WITHOUT embeddings:")
    for row in result_missing:
        print(f"{row['label']}: {row['count']}")

except Exception as e:
    print(f"Error: {e}")

import os

from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph

load_dotenv()

try:
    url = os.getenv("NEO4J_URI")
    username = os.getenv("NEO4J_USERNAME")
    password = os.getenv("NEO4J_PASSWORD")

    graph = Neo4jGraph(url=url, username=username, password=password)

    result = graph.query("""
    MATCH (n)
    RETURN labels(n) as labels, count(n) as count
    """)

    print("All Node Labels:")
    for row in result:
        print(f"{row['labels']}: {row['count']}")

except Exception as e:
    print(f"Error: {e}")

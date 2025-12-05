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
    MATCH (c:Chunk)-[r:REFERENCIA_CODIGO]->(code)
    RETURN type(r) as rel, labels(code) as target_label, count(r) as count
    """)

    print("Links found:")
    for row in result:
        print(f"{row['rel']} -> {row['target_label']}: {row['count']}")

except Exception as e:
    print(f"Error: {e}")

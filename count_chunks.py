import os

from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph

load_dotenv()

try:
    url = os.getenv("NEO4J_URI")
    username = os.getenv("NEO4J_USERNAME")
    password = os.getenv("NEO4J_PASSWORD")

    graph = Neo4jGraph(url=url, username=username, password=password)

    result = graph.query("MATCH (c:Chunk) RETURN count(c) as count")
    print(f"Chunks: {result[0]['count']}")

    result_manual = graph.query("MATCH (m:Manual) RETURN count(m) as count")
    print(f"Manuais: {result_manual[0]['count']}")

except Exception as e:
    print(f"Error: {e}")

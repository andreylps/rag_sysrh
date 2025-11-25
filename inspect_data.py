import os

from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph

load_dotenv()

try:
    url = os.getenv("NEO4J_URI")
    username = os.getenv("NEO4J_USERNAME")
    password = os.getenv("NEO4J_PASSWORD")

    graph = Neo4jGraph(url=url, username=username, password=password)

    print("\n--- Sample Solicitacao ---")
    # Get distinct statuses to fix the filter
    statuses = graph.query(
        "MATCH (s:Solicitacao) RETURN DISTINCT s.status as status LIMIT 20"
    )
    print("Statuses found:", [r["status"] for r in statuses])

    # Get a sample node
    sample_sol = graph.query("MATCH (s:Solicitacao) RETURN s LIMIT 1")
    print("Sample Node:", sample_sol)

    print("\n--- Sample Custo ---")
    custos = graph.query("MATCH (c:Custo) RETURN c")
    print("Custos found:", custos)

except Exception as e:
    print(f"Error: {e}")

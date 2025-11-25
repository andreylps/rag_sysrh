import os

from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph

load_dotenv()

try:
    url = os.getenv("NEO4J_URI")
    username = os.getenv("NEO4J_USERNAME")
    password = os.getenv("NEO4J_PASSWORD")

    print(f"Connecting to {url} as {username}...")

    graph = Neo4jGraph(url=url, username=username, password=password)

    # Query to count nodes by label
    query = """
    MATCH (n)
    RETURN labels(n) as labels, count(n) as count
    ORDER BY count DESC
    """

    print("\n--- Node Counts by Label ---")
    results = graph.query(query)
    for r in results:
        print(f"{r['labels']}: {r['count']}")

    # Check for specific properties in Solicitacao if it exists
    if any("Solicitacao" in r["labels"] for r in results):
        print("\n--- Sample Solicitacao ---")
        sample = graph.query("MATCH (s:Solicitacao) RETURN s LIMIT 1")
        print(sample)

except Exception as e:
    print(f"Error: {e}")

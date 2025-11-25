import os

from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph

load_dotenv()

try:
    url = os.getenv("NEO4J_URI")
    username = os.getenv("NEO4J_USERNAME")
    password = os.getenv("NEO4J_PASSWORD")

    graph = Neo4jGraph(url=url, username=username, password=password)

    print("\n--- Checking Data Availability for Billing ---")

    # Check count of Solicitacoes with valid effort or hours
    query_stats = """
        MATCH (s:Solicitacao)
        RETURN 
            count(s) as total,
            sum(CASE WHEN s.effort IS NOT NULL AND s.effort > 0 THEN 1 ELSE 0 END) as with_effort,
            sum(CASE WHEN s.horas_realizadas IS NOT NULL AND s.horas_realizadas > 0 THEN 1 ELSE 0 END) as with_hours,
            sum(CASE WHEN s.tipo_solicitacao IS NOT NULL THEN 1 ELSE 0 END) as with_type
    """
    stats = graph.query(query_stats)
    print("Stats:", stats)

    # Check distinct types to ensure matching logic is correct
    query_types = """
        MATCH (s:Solicitacao)
        RETURN DISTINCT s.tipo_solicitacao as tipo, count(s) as qtd
    """
    types = graph.query(query_types)
    print("\nTypes found:", types)

    # Check if Custo nodes exist
    custos = graph.query("MATCH (c:Custo) RETURN c.tipo, c.valor")
    print("\nCustos found:", custos)

except Exception as e:
    print(f"Error: {e}")

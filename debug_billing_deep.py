import os

from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph

load_dotenv()

try:
    url = os.getenv("NEO4J_URI")
    username = os.getenv("NEO4J_USERNAME")
    password = os.getenv("NEO4J_PASSWORD")

    graph = Neo4jGraph(url=url, username=username, password=password)

    print("\n--- 1. Checking Custo Nodes ---")
    custos = graph.query(
        "MATCH (c:Custo) RETURN c.tipo, c.valor, apoc.meta.type(c.valor) as val_type"
    )
    for c in custos:
        print(
            f"Type: {c['c.tipo']} | Value: {c['c.valor']} | Neo4jType: {c['val_type']}"
        )

    print("\n--- 2. Checking Solicitacao Nodes (Sample) ---")
    solics = graph.query("""
        MATCH (s:Solicitacao) 
        RETURN s.id, s.tipo_solicitacao, s.effort, apoc.meta.type(s.effort) as eff_type, 
               s.horas_realizadas, apoc.meta.type(s.horas_realizadas) as hr_type
        LIMIT 5
    """)
    for s in solics:
        print(s)

    print("\n--- 3. Testing Match Logic ---")
    # Test if we can join them
    query = """
        MATCH (s:Solicitacao)
        WHERE s.effort IS NOT NULL OR s.horas_realizadas IS NOT NULL
        OPTIONAL MATCH (c:Custo)
        WHERE (toLower(s.tipo_solicitacao) IN ['evolutivo', 'melhoria', 'projeto'] AND c.tipo = 'ponto_funcao')
           OR (NOT toLower(s.tipo_solicitacao) IN ['evolutivo', 'melhoria', 'projeto'] AND c.tipo = 'hora_desenvolvimento')
        RETURN s.id, s.tipo_solicitacao, c.tipo, c.valor
        LIMIT 5
    """
    matches = graph.query(query)
    print(f"Matches found: {len(matches)}")
    for m in matches:
        print(m)

except Exception as e:
    print(f"Error: {e}")

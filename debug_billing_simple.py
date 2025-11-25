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
    custos = graph.query("MATCH (c:Custo) RETURN c.tipo, c.valor")
    if not custos:
        print("❌ NO CUSTO NODES FOUND!")
    for c in custos:
        print(f"Type: {c['c.tipo']} | Value: {c['c.valor']} ({type(c['c.valor'])})")

    print("\n--- 2. Checking Solicitacao Nodes (Sample) ---")
    solics = graph.query("""
        MATCH (s:Solicitacao) 
        RETURN s.id, s.tipo_solicitacao, s.effort, s.horas_realizadas
        LIMIT 5
    """)
    for s in solics:
        print(
            f"ID: {s['s.id']} | Tipo: {s['s.tipo_solicitacao']} | Effort: {s['s.effort']} | Horas: {s['s.horas_realizadas']}"
        )

    print("\n--- 3. Testing Match Logic ---")
    query = """
        MATCH (s:Solicitacao)
        OPTIONAL MATCH (c:Custo)
        WHERE (toLower(s.tipo_solicitacao) IN ['evolutivo', 'melhoria', 'projeto'] AND c.tipo = 'ponto_funcao')
           OR (NOT toLower(s.tipo_solicitacao) IN ['evolutivo', 'melhoria', 'projeto'] AND c.tipo = 'hora_desenvolvimento')
        RETURN s.id, s.tipo_solicitacao, c.tipo, c.valor
        LIMIT 5
    """
    matches = graph.query(query)
    for m in matches:
        print(f"Match: {m}")

except Exception as e:
    print(f"Error: {e}")

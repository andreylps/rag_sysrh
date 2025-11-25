import os

from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph

load_dotenv()

try:
    url = os.getenv("NEO4J_URI")
    username = os.getenv("NEO4J_USERNAME")
    password = os.getenv("NEO4J_PASSWORD")

    graph = Neo4jGraph(url=url, username=username, password=password)

    print("\n--- Debugging Billing Data ---")

    # Check Solicitacao types
    print("1. Solicitacao Types:")
    types = graph.query(
        "MATCH (s:Solicitacao) RETURN DISTINCT s.tipo_solicitacao as tipo, count(s) as qtd"
    )
    for t in types:
        print(f"   - {t['tipo']}: {t['qtd']}")

    # Check Custo nodes
    print("\n2. Custo Nodes:")
    custos = graph.query("MATCH (c:Custo) RETURN c.tipo as tipo, c.valor as valor")
    for c in custos:
        print(f"   - {c['tipo']}: {c['valor']}")

    # Test the Billing Query Logic
    print("\n3. Testing Query Logic:")
    query = """
        MATCH (s:Solicitacao)
        OPTIONAL MATCH (c_pf:Custo {tipo: 'ponto_funcao'})
        OPTIONAL MATCH (c_h:Custo {tipo: 'hora_desenvolvimento'})
        
        WITH s, c_pf, c_h,
             CASE 
                WHEN toLower(s.tipo_solicitacao) IN ['evolutivo', 'melhoria', 'projeto'] 
                THEN coalesce(s.effort, 0) * coalesce(c_pf.valor, 0)
                ELSE coalesce(s.horas_realizadas, 0) * coalesce(c_h.valor, 0)
             END as valor_solicitacao
        
        RETURN 
            s.id as id, 
            s.tipo_solicitacao as tipo, 
            s.effort as effort, 
            s.horas_realizadas as horas, 
            valor_solicitacao
        LIMIT 10
    """
    results = graph.query(query)
    for r in results:
        print(r)

except Exception as e:
    print(f"Error: {e}")

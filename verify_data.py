import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph

# Add src to path
SRC_PATH = Path(__file__).resolve().parent / "src"
if str(SRC_PATH) not in sys.path:
    sys.path.append(str(SRC_PATH))

# Load environment variables
load_dotenv()


def verify_data():
    print("--- Verifying Data Integrity in Neo4j ---")

    try:
        graph = Neo4jGraph(
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
        )

        queries = {
            "Solicitacao": "MATCH (n:Solicitacao) RETURN count(n) as count",
            "RCM": "MATCH (n:RCM) RETURN count(n) as count",
            "CasoDeTeste": "MATCH (n:CasoDeTeste) RETURN count(n) as count",
            "Manual": "MATCH (n:Manual) RETURN count(n) as count",
            "Chunk": "MATCH (n:Chunk) RETURN count(n) as count",
            "Custo": "MATCH (n:Custo) RETURN count(n) as count",
            "RCMs com Testes": "MATCH (r:RCM)-[:TEM_TESTE]->(t:CasoDeTeste) RETURN count(DISTINCT r) as count",
        }

        for label, query in queries.items():
            result = graph.query(query)
            count = result[0]["count"]
            print(f"{label}: {count}")

            if count == 0 and label in ["RCM", "CasoDeTeste"]:
                print(f"WARNING: No nodes found for {label}!")

    except Exception as e:
        print(f"ERROR: {e}")


if __name__ == "__main__":
    verify_data()

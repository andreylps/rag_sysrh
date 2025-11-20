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


def debug_rcm_dates():
    print("--- Debugging RCM Dates in Neo4j ---")

    try:
        graph = Neo4jGraph(
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
        )

        # Check for any RCM with both dates
        query_check = """
        MATCH (rcm:RCM)
        WHERE rcm.data_prevista_entrega IS NOT NULL 
          AND rcm.data_conclusao_real IS NOT NULL
        RETURN count(rcm) as count
        """
        result = graph.query(query_check)
        print(f"RCMs with both dates (NOT NULL check): {result[0]['count']}")

        # Inspect raw values
        query_inspect = """
        MATCH (rcm:RCM)
        RETURN rcm.id, rcm.data_prevista_entrega, rcm.data_conclusao_real
        LIMIT 10
        """
        results = graph.query(query_inspect)
        print("\nSample RCM Data:")
        for r in results:
            print(r)

    except Exception as e:
        print(f"ERROR: {e}")


if __name__ == "__main__":
    debug_rcm_dates()

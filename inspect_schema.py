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


def inspect_rcm_schema():
    print("--- Inspecting RCM Schema in Neo4j ---")

    try:
        graph = Neo4jGraph(
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
        )

        query = "MATCH (n:RCM) RETURN keys(n) as properties LIMIT 1"
        result = graph.query(query)

        if result:
            print(f"RCM Properties: {result[0]['properties']}")
        else:
            print("No RCM nodes found.")

    except Exception as e:
        print(f"ERROR: {e}")


if __name__ == "__main__":
    inspect_rcm_schema()

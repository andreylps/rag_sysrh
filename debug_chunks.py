import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph

# Add src to sys.path
SRC_PATH = Path(__file__).resolve().parent / "src"
if str(SRC_PATH) not in sys.path:
    sys.path.append(str(SRC_PATH))

load_dotenv()


def debug_chunks():
    print("--- Checking for invalid Chunk nodes ---")

    try:
        graph = Neo4jGraph(
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
        )

        # Check for nodes with missing 'texto' property
        query_missing = "MATCH (c:Chunk) WHERE c.texto IS NULL RETURN count(c) as count"
        result_missing = graph.query(query_missing)
        count_missing = result_missing[0]["count"]
        print(f"Chunks with NULL 'texto': {count_missing}")

        # Check for nodes with empty string 'texto'
        query_empty = "MATCH (c:Chunk) WHERE c.texto = '' RETURN count(c) as count"
        result_empty = graph.query(query_empty)
        count_empty = result_empty[0]["count"]
        print(f"Chunks with EMPTY 'texto': {count_empty}")

        if count_missing > 0 or count_empty > 0:
            print("Found invalid chunks. Deleting them...")

            # Delete NULLs
            if count_missing > 0:
                graph.query("MATCH (c:Chunk) WHERE c.texto IS NULL DETACH DELETE c")
                print(f"Deleted {count_missing} chunks with NULL texto.")

            # Delete Empty strings
            if count_empty > 0:
                graph.query("MATCH (c:Chunk) WHERE c.texto = '' DETACH DELETE c")
                print(f"Deleted {count_empty} chunks with EMPTY texto.")

            print("Cleanup complete.")
        else:
            print(
                "No invalid chunks found. The error might be related to something else or specific nodes."
            )

    except Exception as e:
        print(f"Error connecting to Neo4j: {e}")


if __name__ == "__main__":
    debug_chunks()

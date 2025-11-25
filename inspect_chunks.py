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


def inspect_chunks():
    print("--- Inspecting Chunk Content ---")

    try:
        graph = Neo4jGraph(
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
        )

        # 1. Total Chunks
        count = graph.query("MATCH (c:Chunk) RETURN count(c) as count")[0]["count"]
        print(f"Total Chunks: {count}")

        if count == 0:
            print("❌ No chunks found! You need to run ingestion.")
            return

        # 2. Search for "mantel" or "edital" (case insensitive)
        query_search = """
        MATCH (c:Chunk)
        WHERE toLower(c.texto) CONTAINS 'mantel' OR toLower(c.texto) CONTAINS 'edital'
        RETURN c.texto as text, c.source as source
        LIMIT 3
        """
        results = graph.query(query_search)

        if results:
            print(f"✅ Found {len(results)} chunks containing keywords:")
            for r in results:
                print(f"Source: {r.get('source', 'Unknown')}")
                print(f"Snippet: {r['text'][:100]}...")
                print("-" * 20)
        else:
            print("❌ No chunks found containing 'mantel' or 'edital'.")

            # Show random sample
            print("Sample of existing content:")
            sample = graph.query("MATCH (c:Chunk) RETURN c.texto as text LIMIT 1")
            if sample:
                print(f"Snippet: {sample[0]['text'][:100]}...")

    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    inspect_chunks()

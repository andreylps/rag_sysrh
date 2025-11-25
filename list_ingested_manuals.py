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


def list_manuals():
    output_file = "ingested_manuals.txt"
    print(f"--- Listing Ingested Manuals to {output_file} ---")

    try:
        graph = Neo4jGraph(
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
        )

        # Query Manual nodes
        query = "MATCH (m:Manual) RETURN m.nome as nome ORDER BY m.nome"
        results = graph.query(query)

        with open(output_file, "w", encoding="utf-8") as f:
            if results:
                f.write(f"Encontrados {len(results)} manuais:\n")
                for r in results:
                    f.write(f"- {r['nome']}\n")
                print(f"✅ Successfully wrote {len(results)} manuals to {output_file}")
            else:
                f.write("Nenhum manual encontrado no banco de dados.\n")
                print("❌ No manuals found.")

    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    list_manuals()

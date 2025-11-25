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


def verify_data():
    output_file = "ingested_system_data.txt"
    print(f"--- Verifying Ingested System Data to {output_file} ---")

    try:
        graph = Neo4jGraph(
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
        )

        with open(output_file, "w", encoding="utf-8") as f:
            # 1. Solicitacoes
            count_solic = graph.query("MATCH (s:Solicitacao) RETURN count(s) as count")[
                0
            ]["count"]
            f.write(f"✅ Solicitacoes: {count_solic} (Origem: data/solicitacoes.csv)\n")

            # 2. Custos
            count_custo = graph.query("MATCH (c:Custo) RETURN count(c) as count")[0][
                "count"
            ]
            f.write(f"✅ Custos: {count_custo} (Origem: data/faturamento/custos.csv)\n")

            # 3. RCMs
            count_rcm = graph.query("MATCH (r:RCM) RETURN count(r) as count")[0][
                "count"
            ]
            f.write(f"✅ RCMs (Metadados): {count_rcm} (Origem: data/rcms_01.csv)\n")

            # 4. Casos de Teste
            count_tests = graph.query("MATCH (t:CasoDeTeste) RETURN count(t) as count")[
                0
            ]["count"]
            f.write(
                f"✅ Casos de Teste: {count_tests} (Origem: data/casos_de_teste.csv)\n"
            )

            # 5. RCM Documents (Chunks linked to RCM)
            count_rcm_chunks = graph.query(
                "MATCH (c:Chunk)-[:PARTE_DE]->(r:RCM) RETURN count(c) as count"
            )[0]["count"]
            f.write(
                f"✅ Documentos de RCM (Chunks): {count_rcm_chunks} (Origem: data/rcms/*.docx)\n"
            )

            print(f"Verification complete. Results saved to {output_file}")

    except Exception as e:
        print(f"Error connecting to Neo4j: {e}")


if __name__ == "__main__":
    verify_data()

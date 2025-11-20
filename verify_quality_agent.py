import sys
from pathlib import Path

from dotenv import load_dotenv

# Add src to path
SRC_PATH = Path(__file__).resolve().parent / "src"
if str(SRC_PATH) not in sys.path:
    sys.path.append(str(SRC_PATH))

# Load environment variables
load_dotenv()

from rag_sysrh.agente_qualidade import AgenteQualidade  # noqa: E402


def verify_quality_agent():
    print("--- Verifying Quality Agent Deadline Monitoring ---")

    agent = AgenteQualidade()

    # Run the full management cycle
    print("Running management cycle...")
    report = agent.executar_ciclo_gerencial(
        status_callback=lambda msg: print(f"[STATUS] {msg}")
    )

    print("\n--- Generated Report ---")
    print(report)
    print("------------------------")

    # Verify nodes in Neo4j
    print("\nVerifying Neo4j nodes...")
    result = agent.graph.query("MATCH (n:AvaliacaoPrazo) RETURN count(n) as count")
    count = result[0]["count"]
    print(f"AvaliacaoPrazo nodes created: {count}")

    if count > 0:
        print("SUCCESS: Deadline evaluations were created.")
    else:
        print(
            "WARNING: No deadline evaluations created. Check if there are RCMs with dates."
        )


if __name__ == "__main__":
    verify_quality_agent()

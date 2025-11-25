import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from langchain_neo4j import Neo4jVector
from langchain_openai import OpenAIEmbeddings

# Add src to sys.path
SRC_PATH = Path(__file__).resolve().parent / "src"
if str(SRC_PATH) not in sys.path:
    sys.path.append(str(SRC_PATH))

load_dotenv()


def debug_scores():
    print("--- Debugging RAG Scores ---")

    try:
        url = os.getenv("NEO4J_URI")
        username = os.getenv("NEO4J_USERNAME")
        password = os.getenv("NEO4J_PASSWORD")
        openai_api_key = os.getenv("OPENAI_API_KEY")

        embeddings = OpenAIEmbeddings(openai_api_key=openai_api_key)

        vectorstore = Neo4jVector.from_existing_index(
            embedding=embeddings,
            url=url,
            username=username,
            password=password,
            index_name="manual-chunks",
            text_node_property="texto",
        )

        queries = [
            "como opero o manter edital?",  # Should be relevant
            "qual a capital dos EUA?",  # Should be irrelevant
            "quem ganhou a copa de 2022?",  # Should be irrelevant
        ]

        for query in queries:
            print(f"\nQuery: '{query}'")
            results = vectorstore.similarity_search_with_score(query, k=3)
            for doc, score in results:
                print(f"   Score: {score:.4f} | Content: {doc.page_content[:50]}...")

    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    debug_scores()

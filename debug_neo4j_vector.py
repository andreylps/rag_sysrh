import logging
import os

from dotenv import load_dotenv
from langchain_community.vectorstores import Neo4jVector
from langchain_openai import OpenAIEmbeddings

load_dotenv()

logging.basicConfig(level=logging.INFO)

try:
    embeddings = OpenAIEmbeddings()

    # Test 1: Try with hyphen (current state)
    print("--- Test 1: Index with hyphen 'manual-chunks' ---")
    try:
        vector_store = Neo4jVector.from_existing_graph(
            embedding=embeddings,
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
            index_name="manual-chunks",
            node_label="Chunk",
            text_node_properties=["texto"],
            embedding_node_property="embedding",
        )
        print("✅ Test 1 Success")
    except Exception as e:
        print(f"❌ Test 1 Failed: {e}")

    # Test 2: Try with underscore (potential fix)
    print("\n--- Test 2: Index with underscore 'manual_chunks' ---")
    try:
        vector_store = Neo4jVector.from_existing_graph(
            embedding=embeddings,
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
            index_name="manual_chunks",
            node_label="Chunk",
            text_node_properties=["texto"],
            embedding_node_property="embedding",
        )
        print("✅ Test 2 Success")
    except Exception as e:
        print(f"❌ Test 2 Failed: {e}")

except Exception as e:
    print(f"Critical Error: {e}")

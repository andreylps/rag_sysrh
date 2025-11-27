import os

from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph

load_dotenv()

uri = os.getenv("NEO4J_URI")
username = os.getenv("NEO4J_USERNAME")
password = os.getenv("NEO4J_PASSWORD")

print(f"Testing connection to: {uri}")
print(f"Username: {username}")
print(f"Password: {'*' * len(password) if password else 'None'}")

try:
    graph = Neo4jGraph(url=uri, username=username, password=password)
    graph.query("RETURN 1")
    print("✅ Connection SUCCESS!")
except Exception as e:
    print(f"❌ Connection FAILED: {e}")

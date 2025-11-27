try:
    from langchain_neo4j import GraphCypherQAChain

    print("✅ langchain_neo4j imported successfully")
except ImportError as e:
    print(f"❌ langchain_neo4j failed: {e}")

try:
    import langchain_core.memory

    print("✅ langchain_core.memory exists")
except ImportError as e:
    print(f"❌ langchain_core.memory failed: {e}")

import os

from src.rag_sysrh.agente_documentacao import AgenteDocumentacao

# Force Gemini
os.environ["LLM_PROVIDER"] = "gemini"
# Ensure API key is present (mock if needed for import test, but real needed for init)
if not os.getenv("GOOGLE_API_KEY"):
    print("⚠️ GOOGLE_API_KEY not found in env. Test might fail if it tries to connect.")

try:
    print("Attempting to initialize AgenteDocumentacao with Gemini...")
    agent = AgenteDocumentacao()
    print("✅ AgenteDocumentacao initialized successfully with Gemini!")
    print(f"Embeddings: {type(agent.embeddings)}")
    print(f"Index Name: {agent._NEO4J_VECTOR_INDEX_NAME}")
except Exception as e:
    print(f"❌ Failed to initialize: {e}")

import logging

from dotenv import load_dotenv

# Configure logging to show everything
logging.basicConfig(level=logging.INFO)

load_dotenv()

print("--- Testing AgenteDocumentacao ---")
try:
    from src.rag_sysrh.agente_documentacao import AgenteDocumentacao

    agent_docs = AgenteDocumentacao()
    print("✅ AgenteDocumentacao initialized successfully!")
except Exception as e:
    print(f"❌ AgenteDocumentacao FAILED: {e}")
    import traceback

    traceback.print_exc()

print("\n--- Testing AgenteBI ---")
try:
    from src.rag_sysrh.agente_bi import AgenteBI

    agent_bi = AgenteBI()
    print("✅ AgenteBI initialized successfully!")
except Exception as e:
    print(f"❌ AgenteBI FAILED: {e}")
    import traceback

    traceback.print_exc()

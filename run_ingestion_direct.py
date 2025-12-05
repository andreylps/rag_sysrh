import os
import sys

from dotenv import load_dotenv

# Add src to path
sys.path.append(os.getcwd())

load_dotenv()

from src.rag_sysrh.ingestion_service import run_selective_ingestion

print("Iniciando ingestão de dados do sistema (solicitacoes.csv)...")
try:
    result = run_selective_ingestion(selected_manuals=[], ingest_system_data=True)
    print(f"Resultado: {result}")
except Exception as e:
    print(f"Erro: {e}")

import logging

from src.rag_sysrh.data_ingestion import DataIngestion

# Configura logging para ver o que está acontecendo
logging.basicConfig(level=logging.INFO)

print("Iniciando ingestão de custos...")

# Instancia a classe de ingestão
ingestor = DataIngestion(
    data_directory="data",
    structured_data_path="data/solicitacoes.csv",
    rcm_data_path="data/rcms_01.csv",
)

# Chama apenas o método de ingestão de custos (que é privado, mas acessível em Python)
# Isso evita limpar o banco todo
try:
    ingestor._load_and_ingest_cost_data()
    print("✅ Custos ingeridos com sucesso!")
except Exception as e:
    print(f"❌ Erro ao ingerir custos: {e}")

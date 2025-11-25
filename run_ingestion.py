import logging
import os
import sys

# Add src to sys.path
sys.path.append(os.path.join(os.path.dirname(__file__), "src"))

from src.rag_sysrh.ingestion_service import run_selective_ingestion

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def main():
    logger.info("Starting data ingestion...")
    try:
        # Reverted to selective ingestion to prevent massive embedding usage
        # You can add specific manuals to the list below if needed
        selected_manuals = [
            # "SIGRH - AFA - Afastamentos/UCS0007 - Consultar Tipos de Eventos.DOCX"
        ]

        logger.info(
            f"Ingesting system data and {len(selected_manuals)} selected manuals."
        )

        # Ingest system data (Solicitacoes, RCMs) and selected manuals
        result = run_selective_ingestion(
            selected_manuals=selected_manuals, ingest_system_data=True
        )
        logger.info(f"Ingestion result: {result}")

    except Exception as e:
        logger.error(f"Ingestion failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()

import logging
import sys
from pathlib import Path

import pandas as pd

# Add src to path
SRC_PATH = Path(__file__).resolve().parent / "src"
if str(SRC_PATH) not in sys.path:
    sys.path.append(str(SRC_PATH))

from rag_sysrh.services.strategic_data_service import StrategicDataService

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def test_strategic_service():
    logger.info("Iniciando teste do StrategicDataService...")

    try:
        service = StrategicDataService()
        logger.info("Serviço instanciado com sucesso.")

        # Teste 1: Carregamento de dados
        df = service.df
        logger.info(f"DataFrame carregado com {len(df)} registros.")

        if df.empty:
            logger.warning(
                "DataFrame está vazio! Verifique se o CSV existe e tem dados."
            )

        # Teste 2: Verificação de tipos de data
        if "data_criacao" in df.columns:
            is_datetime = pd.api.types.is_datetime64_any_dtype(df["data_criacao"])
            logger.info(f"Coluna 'data_criacao' é datetime? {is_datetime}")
            if not is_datetime:
                logger.error(
                    "ERRO: 'data_criacao' não foi convertida para datetime corretamente."
                )
        else:
            logger.error("ERRO: Coluna 'data_criacao' não encontrada no DataFrame.")

        # Teste 3: Execução de análise (Health Scan)
        logger.info("Executando get_operational_health_scan...")
        scan = service.get_operational_health_scan(period="30d")
        logger.info(f"Scan resultado: {scan.keys()}")

        logger.info("Teste concluído com sucesso!")

    except Exception as e:
        logger.error(f"FALHA NO TESTE: {e}", exc_info=True)


if __name__ == "__main__":
    test_strategic_service()

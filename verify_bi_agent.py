import logging
import sys
from pathlib import Path

# Add src to path
SRC_PATH = Path(__file__).resolve().parent / "src"
if str(SRC_PATH) not in sys.path:
    sys.path.append(str(SRC_PATH))

from dotenv import load_dotenv

from rag_sysrh.agente_bi import AgenteBI

# Configuração de Logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
load_dotenv()


def verify_bi_agent():
    """
    Verifica a funcionalidade do AgenteBI (Text-to-Cypher).
    """
    logging.info("--- INICIANDO VERIFICAÇÃO DO AGENTE BI ---")

    try:
        agente = AgenteBI()

        # Pergunta 1: Contagem simples
        pergunta1 = "Quantas solicitações existem no total?"
        logging.info(f"Pergunta: {pergunta1}")
        resposta1 = agente.responder_pergunta(pergunta1)
        logging.info(f"Resposta: {resposta1['resposta']}")
        logging.info(f"Cypher: {resposta1['cypher']}")

        # Pergunta 2: Filtro
        pergunta2 = "Quais solicitações estão com status 'Pendente'?"
        logging.info(f"Pergunta: {pergunta2}")
        resposta2 = agente.responder_pergunta(pergunta2)
        logging.info(f"Resposta: {resposta2['resposta']}")
        logging.info(f"Cypher: {resposta2['cypher']}")

    except Exception as e:
        logging.error(f"Erro durante a verificação: {e}")
        import traceback

        traceback.print_exc()


if __name__ == "__main__":
    verify_bi_agent()

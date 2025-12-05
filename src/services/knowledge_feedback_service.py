import json
import logging
import os
from datetime import datetime
from typing import List

from pypdf import PdfReader

# Assumindo que temos um cliente Neo4j configurado ou usaremos um mock por enquanto se não estiver acessível diretamente
# from src.core.database import neo4j_driver

logger = logging.getLogger(__name__)

REPORTS_DIR = "data/reports/pdca"
DIRECTIVES_FILE = "data/project_directives.json"  # Fallback/Persistência simples


class KnowledgeFeedbackService:
    def __init__(self):
        self._ensure_directives_file()

    def _ensure_directives_file(self):
        if not os.path.exists(DIRECTIVES_FILE):
            os.makedirs(os.path.dirname(DIRECTIVES_FILE), exist_ok=True)
            with open(DIRECTIVES_FILE, "w", encoding="utf-8") as f:
                json.dump([], f)

    def process_latest_pdca_report(self):
        """
        Localiza o último relatório PDCA, extrai texto e gera diretrizes.
        """
        try:
            latest_report = self._find_latest_report()
            if not latest_report:
                logger.info("Nenhum relatório PDCA encontrado para processar.")
                return

            logger.info(f"Processando relatório para feedback: {latest_report}")
            text_content = self._extract_text_from_pdf(latest_report)

            directives = self._extract_directives_with_llm(text_content)

            if directives:
                self.ingest_project_directives(directives)
                logger.info(
                    f"Ciclo de feedback concluído. {len(directives)} novas diretrizes ingeridas."
                )
            else:
                logger.warning("Nenhuma diretriz foi extraída do relatório.")

        except Exception as e:
            logger.error(f"Erro no ciclo de feedback de conhecimento: {e}")

    def _find_latest_report(self) -> str:
        if not os.path.exists(REPORTS_DIR):
            return None

        files = [
            os.path.join(REPORTS_DIR, f)
            for f in os.listdir(REPORTS_DIR)
            if f.endswith(".pdf")
        ]
        if not files:
            return None

        return max(files, key=os.path.getctime)

    def _extract_text_from_pdf(self, file_path: str) -> str:
        reader = PdfReader(file_path)
        text = ""
        for page in reader.pages:
            text += page.extract_text() + "\n"
        return text

    def _extract_directives_with_llm(self, text: str) -> List[str]:
        """
        Simula a chamada ao LLM para extrair diretrizes.
        Em produção, isso chamaria o serviço de LLM real.
        """
        # TODO: Integrar com o serviço de LLM real (ex: Gemini/OpenAI)
        # Por enquanto, vamos simular uma extração baseada em palavras-chave ou retornar um mock inteligente

        logger.info("Enviando conteúdo do relatório para o LLM (Simulado)...")

        # Mock de resposta do LLM
        mock_directives = [
            f"Diretriz gerada em {datetime.now().strftime('%d/%m %H:%M')}: Validar sempre os inputs de data.",
            "Evitar uso de 'print' em produção, usar 'logger'.",
            "Manter funções com no máximo 20 linhas para facilitar testes.",
        ]

        return mock_directives

    def ingest_project_directives(self, directives: List[str]):
        """
        Armazena as diretrizes. Tenta Neo4j, fallback para JSON.
        """
        # 1. Persistência em JSON (Simples e garantida)
        self._save_to_json(directives)

        # 2. Persistência em Neo4j (Se disponível)
        # self._save_to_neo4j(directives)

    def _save_to_json(self, directives: List[str]):
        try:
            with open(DIRECTIVES_FILE, "r", encoding="utf-8") as f:
                current_data = json.load(f)

            new_entries = [
                {
                    "content": d,
                    "created_at": datetime.now().isoformat(),
                    "source": "PDCA_FEEDBACK",
                }
                for d in directives
            ]

            current_data.extend(new_entries)

            with open(DIRECTIVES_FILE, "w", encoding="utf-8") as f:
                json.dump(current_data, f, indent=2, ensure_ascii=False)

        except Exception as e:
            logger.error(f"Erro ao salvar diretrizes em JSON: {e}")

    def get_recent_directives(self, limit=5) -> List[str]:
        """
        Retorna as diretrizes mais recentes para injeção no prompt.
        """
        try:
            with open(DIRECTIVES_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)

            # Ordenar por data decrescente
            sorted_data = sorted(data, key=lambda x: x["created_at"], reverse=True)
            return [item["content"] for item in sorted_data[:limit]]
        except Exception as e:
            logger.error(f"Erro ao ler diretrizes: {e}")
            return []


knowledge_feedback_service = KnowledgeFeedbackService()

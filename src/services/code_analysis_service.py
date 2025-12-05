import logging
import os

import radon.metrics as radon_metrics
from radon.visitors import ComplexityVisitor

logger = logging.getLogger(__name__)


class CodeAnalysisService:
    """
    Serviço responsável pela análise estática de código usando Radon.
    Calcula métricas como Complexidade Ciclomática (CC) e Índice de Manutenibilidade (MI).
    """

    def __init__(self, source_dir: str = "src"):
        self.source_dir = source_dir

    def _get_python_files(self) -> list[str]:
        """Retorna uma lista de todos os arquivos Python no diretório fonte."""
        py_files = []
        for root, _, files in os.walk(self.source_dir):
            for file in files:
                if file.endswith(".py"):
                    py_files.append(os.path.join(root, file))
        return py_files

    def analyze_complexity(self) -> float:
        """
        Calcula a Complexidade Ciclomática média do projeto.
        """
        total_cc = 0
        total_blocks = 0

        files = self._get_python_files()
        if not files:
            return 0.0

        for file_path in files:
            try:
                with open(file_path, encoding="utf-8") as f:
                    code = f.read()
                    visitor = ComplexityVisitor.from_code(code)
                    for function in visitor.functions:
                        total_cc += function.complexity
                        total_blocks += 1
                    # Classes também podem ser visitadas se necessário, mas functions dão boa média
            except Exception as e:
                logger.warning(f"Erro ao analisar complexidade de {file_path}: {e}")

        if total_blocks == 0:
            return 0.0

        return round(total_cc / total_blocks, 2)

    def analyze_maintainability(self) -> float:
        """
        Calcula o Índice de Manutenibilidade (MI) médio do projeto.
        MI > 50 é bom (A), < 20 é ruim (C).
        """
        total_mi = 0
        count = 0

        files = self._get_python_files()
        if not files:
            return 0.0

        for file_path in files:
            try:
                with open(file_path, encoding="utf-8") as f:
                    code = f.read()
                    mi = radon_metrics.mi_visit(code, multi=False)
                    total_mi += mi
                    count += 1
            except Exception as e:
                logger.warning(f"Erro ao analisar manutenibilidade de {file_path}: {e}")

        if count == 0:
            return 0.0

        return round(total_mi / count, 2)

    def estimate_technical_debt(self, mi_score: float) -> float:
        """
        Estima a Dívida Técnica (%) baseada no Índice de Manutenibilidade.
        Heurística: MI=100 -> 0% dívida, MI=0 -> 100% dívida.
        Na prática, MI < 50 já é problemático.
        """
        # Inverter a escala: quanto menor o MI, maior a dívida.
        # MI ideal é ~100.
        debt = max(0, 100 - mi_score)
        return round(debt, 2)


# Instância global
code_analysis_service = CodeAnalysisService()

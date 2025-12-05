import json
import logging
import os
from datetime import datetime
from typing import Any, Dict

from rag_sysrh.interfaces import ExternalConnector


class GitHubMockConnector(ExternalConnector):
    """
    Simula a integração com o GitHub Issues, escrevendo em um arquivo JSON local.
    """

    def __init__(self, mock_file_path: str = "data/external_system/github_mock.json"):
        self.mock_file_path = mock_file_path
        self._ensure_directory()

    def _ensure_directory(self):
        """Garante que o diretório do arquivo mock exista."""
        directory = os.path.dirname(self.mock_file_path)
        if directory and not os.path.exists(directory):
            os.makedirs(directory)

    def create_issue(self, rcm_data: Dict[str, Any]) -> str:
        """
        Simula a criação de uma issue no GitHub.
        """
        logging.info(
            f"Simulando criação de issue no GitHub para RCM: {rcm_data.get('titulo_rcm')}"
        )

        # Carrega issues existentes
        issues = []
        if os.path.exists(self.mock_file_path):
            try:
                with open(self.mock_file_path, "r", encoding="utf-8") as f:
                    issues = json.load(f)
            except json.JSONDecodeError:
                issues = []

        # Gera um ID simulado (como se fosse o número da issue)
        issue_number = len(issues) + 1
        issue_url = f"https://github.com/mock-org/mock-repo/issues/{issue_number}"

        # Cria o objeto da issue simulada
        new_issue = {
            "number": issue_number,
            "title": f"[RCM] {rcm_data.get('titulo_rcm')}",
            "body": self._format_body(rcm_data),
            "labels": ["RCM", "Automated"],
            "state": "open",
            "created_at": datetime.now().isoformat(),
            "html_url": issue_url,
        }

        issues.append(new_issue)

        # Salva no arquivo
        with open(self.mock_file_path, "w", encoding="utf-8") as f:
            json.dump(issues, f, indent=2, ensure_ascii=False)

        return issue_url

    def _format_body(self, rcm_data: Dict[str, Any]) -> str:
        """Formata o corpo da issue em Markdown."""
        return f"""
### Descrição
{rcm_data.get("descricao_tecnica_detalhada", "Sem descrição")}

### Objetivo de Negócio
{rcm_data.get("objetivo_negocio", "N/A")}

### Estimativa
- **Pontos de Função:** {rcm_data.get("estimativa_pontos_funcao", "N/A")}
- **Prazo:** {rcm_data.get("prazo_dias_uteis", "N/A")} dias úteis

### Critérios de Aceite
{self._format_list(rcm_data.get("criterios_de_aceite", []))}

---
*Gerado automaticamente pelo Agente de Planejamento RAG_SYSRH*
"""

    def _format_list(self, items: list) -> str:
        if not items:
            return "Nenhum"
        return "\n".join([f"- {item}" for item in items])

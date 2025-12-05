import logging
import os
from typing import Any, Dict

from dotenv import load_dotenv
from github import Github, GithubException

from rag_sysrh.interfaces import ExternalConnector

# Configura o logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)

load_dotenv()


class GitHubConnector(ExternalConnector):
    """
    Conector para interagir com a API do GitHub.
    Permite listar, obter e criar issues (RCMs).
    """

    def __init__(self, token: str | None = None, repo_name: str | None = None) -> None:
        """
        Inicializa o conector do GitHub.

        Args:
            token (str | None): Token de acesso pessoal do GitHub (PAT).
                                Se None, tenta ler da variável de ambiente GITHUB_TOKEN.
            repo_name (str | None): Nome do repositório (ex: "usuario/repo").
                                    Se None, tenta ler de GITHUB_REPO_NAME ou falha na execução.
        """
        self.token = token or os.getenv("GITHUB_TOKEN")
        self.repo_name = repo_name or os.getenv("GITHUB_REPO_NAME")

        if self.repo_name and self.repo_name.endswith(".git"):
            self.repo_name = self.repo_name[:-4]

        if not self.token:
            logging.warning(
                "GITHUB_TOKEN não encontrado. O conector funcionará em modo restrito ou falhará."
            )

        self.github = Github(self.token) if self.token else None

    def _get_repo(self) -> Any:
        """Recupera o objeto do repositório."""
        if not self.github:
            msg = "Cliente GitHub não inicializado (Token ausente)."
            raise ValueError(msg)
        if not self.repo_name:
            msg = "Nome do repositório não configurado (GITHUB_REPO_NAME)."
            raise ValueError(msg)
        return self.github.get_repo(self.repo_name)

    def list_issues(
        self, state: str = "open", labels: list[str] | None = None
    ) -> list[dict]:
        """
        Lista as issues do repositório.

        Args:
            state (str): Estado das issues ('open', 'closed', 'all').
            labels (list[str] | None): Lista de labels para filtrar.

        Returns:
            list[dict]: Lista de dicionários com dados básicos das issues.
        """
        try:
            repo = self._get_repo()
            kwargs = {"state": state}
            if labels:
                kwargs["labels"] = labels

            issues = repo.get_issues(**kwargs)

            results = []
            for issue in issues:
                results.append(
                    {
                        "number": issue.number,
                        "title": issue.title,
                        "state": issue.state,
                        "html_url": issue.html_url,
                        "labels": [label.name for label in issue.labels],
                    }
                )
            return results

        except GithubException as e:
            logging.error(f"Erro ao listar issues do GitHub: {e}")
            return []
        except Exception as e:
            logging.error(f"Erro inesperado ao listar issues: {e}")
            return []

    def create_issue(self, rcm_data: Dict[str, Any]) -> str:
        """
        Cria uma nova issue no GitHub baseada nos dados da RCM.

        Args:
            rcm_data (Dict[str, Any]): Dados da RCM (titulo_rcm, descricao, etc).

        Returns:
            str: URL da issue criada ou None em caso de erro.
        """
        try:
            repo = self._get_repo()

            title = f"[RCM] {rcm_data.get('titulo_rcm', 'Nova RCM')}"
            body = self._format_body(rcm_data)
            labels = ["RCM", "Pendente Aprovação"]

            # Adiciona label de tipo se existir
            tipo = rcm_data.get("tipo_solicitacao")
            if tipo:
                labels.append(tipo)

            issue = repo.create_issue(title=title, body=body, labels=labels)

            logging.info(f"Issue criada com sucesso: {issue.html_url}")
            return issue.html_url

        except GithubException as e:
            logging.error(f"Erro ao criar issue no GitHub: {e}")
            raise  # Propaga o erro para ser tratado no app
        except Exception as e:
            logging.error(f"Erro inesperado ao criar issue: {e}")
            raise

    def get_issue(self, issue_number: int) -> dict | None:
        """Recupera detalhes de uma issue específica."""
        try:
            repo = self._get_repo()
            issue = repo.get_issue(issue_number)
            return {
                "number": issue.number,
                "title": issue.title,
                "body": issue.body,
                "state": issue.state,
                "html_url": issue.html_url,
                "labels": [label.name for label in issue.labels],
                "comments": issue.comments,
            }
        except Exception as e:
            logging.error(f"Erro ao recuperar issue {issue_number}: {e}")
            return None

    def _format_body(self, rcm_data: Dict[str, Any]) -> str:
        """Formata o corpo da issue em Markdown usando os dados da RCM."""

        tarefas = rcm_data.get("plano_de_tarefas_sugerido", [])
        if isinstance(tarefas, list):
            tarefas_md = "\n".join([f"- [ ] {t}" for t in tarefas])
        else:
            tarefas_md = str(tarefas)

        criterios = rcm_data.get("criterios_de_aceite", [])
        if isinstance(criterios, list):
            criterios_md = "\n".join([f"- {c}" for c in criterios])
        else:
            criterios_md = str(criterios)

        riscos = rcm_data.get("riscos_mapeados", [])
        if isinstance(riscos, list):
            riscos_md = "\n".join([f"- {r}" for r in riscos])
        else:
            riscos_md = str(riscos)

        return f"""
## Solicitação de Mudança (RCM)
*Gerada automaticamente pelo Agente SYSRH*

### Objetivo de Negócio
{rcm_data.get("objetivo_negocio", "N/A")}

### Descrição Técnica
{rcm_data.get("descricao_tecnica_detalhada", "N/A")}

### Plano de Execução
{tarefas_md}

### Critérios de Aceite
{criterios_md}

### Riscos
{riscos_md}

---
**Estimativas:**
- **Esforço:** {rcm_data.get("estimativa_pontos_funcao", "N/A")} PF
- **Prazo:** {rcm_data.get("prazo_dias_uteis", "N/A")} dias úteis
"""

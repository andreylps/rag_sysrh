# src/services/github_service.py

import asyncio
import logging
import os

from dotenv import load_dotenv
from github import Github

# Configura logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

load_dotenv()


def get_github_client():
    token = os.getenv("GITHUB_TOKEN")
    if not token:
        raise ValueError("GITHUB_TOKEN not found in environment variables.")
    return Github(token)


def get_repo_name():
    repo_name = os.getenv("GITHUB_REPO_NAME")
    if not repo_name:
        raise ValueError("GITHUB_REPO_NAME not found in environment variables.")
    # Remove .git extension if present
    if repo_name.endswith(".git"):
        repo_name = repo_name[:-4]
    return repo_name


async def create_issue(title: str, body: str) -> int:
    """
    Cria uma issue no GitHub de forma assíncrona.
    Retorna o número da issue criada.
    """

    def _create_sync():
        g = get_github_client()
        repo_name = get_repo_name()
        repo = g.get_repo(repo_name)
        issue = repo.create_issue(title=title, body=body)
        logger.info(f"Issue criada com sucesso: #{issue.number}")
        return issue.number

    return await asyncio.to_thread(_create_sync)


async def post_comment(issue_number: int, body: str) -> None:
    """
    Posta um comentário em uma issue existente de forma assíncrona.
    """

    def _post_sync():
        g = get_github_client()
        repo_name = get_repo_name()
        repo = g.get_repo(repo_name)
        issue = repo.get_issue(issue_number)
        issue.create_comment(body)
        logger.info(f"Comentário postado na issue #{issue_number}")

    await asyncio.to_thread(_post_sync)


async def list_issues_by_label(label: str, state: str = "open") -> list[dict]:
    """
    Lista as issues do repositório filtradas por uma label específica de forma assíncrona.
    Útil para buscar backlogs (ex: 'status:aguardando-validacao').

    Args:
        label (str): A label exata para filtrar.
        state (str): O estado das issues ('open', 'closed', 'all'). Padrão 'open'.

    Returns:
        list[dict]: Uma lista simplificada de issues.
    """

    def _list_sync():
        g = get_github_client()
        repo_name = get_repo_name()
        repo = g.get_repo(repo_name)

        logger.info(
            f"Buscando issues no GitHub com label='{label}' e state='{state}'..."
        )

        # A biblioteca PyGithub permite filtrar por label passando uma lista
        # O state padrão já é 'open'
        issues_paginated = repo.get_issues(
            state=state, labels=[label], sort="created", direction="asc"
        )

        # Limpa o resultado, retornando apenas os campos necessários para o frontend
        cleaned_issues = []
        # Itera sobre o resultado paginado (o PyGithub faz as chamadas de API conforme necessário)
        for issue in issues_paginated:
            # O PyGithub retorna apenas issues, não PRs, quando usamos get_issues()
            cleaned_issues.append(
                {
                    "github_id": issue.id,  # ID interno do GitHub
                    "number": issue.number,  # Número visível da issue (ex: #42)
                    "title": issue.title,
                    "html_url": issue.html_url,  # Link para abrir no navegador
                    "created_at": issue.created_at.isoformat(),  # Converte datetime para string ISO
                    # Extrai apenas os nomes das labels (CORREÇÃO AQUI: 'l' virou 'lbl')
                    "labels": [lbl.name for lbl in issue.labels],
                }
            )

        logger.info(f"Encontradas {len(cleaned_issues)} issues válidas.")
        return cleaned_issues

    # Executa a função síncrona em uma thread separada
    return await asyncio.to_thread(_list_sync)


# --- Adicione estas funções ao final do arquivo src/services/github_service.py ---


def _get_issue_sync(issue_number: int):
    """Helper interno para recuperar o objeto Issue do PyGithub de forma síncrona."""
    g = get_github_client()
    repo_name = get_repo_name()
    repo = g.get_repo(repo_name)
    return repo.get_issue(issue_number)


async def update_issue_labels(
    issue_number: int, add_labels: list[str] = None, remove_labels: list[str] = None
) -> None:
    """
    Atualiza as labels de uma issue (adiciona e/ou remove).
    """

    def _update_sync():
        issue = _get_issue_sync(issue_number)
        logger.info(f"Atualizando labels da issue #{issue_number}...")

        if add_labels:
            # PyGithub aceita múltiplos argumentos posicionais
            issue.add_to_labels(*add_labels)
            logger.info(f"Labels adicionadas: {add_labels}")

        if remove_labels:
            current_labels = [l.name for l in issue.labels]
            for label_to_remove in remove_labels:
                if label_to_remove in current_labels:
                    try:
                        issue.remove_from_labels(label_to_remove)
                        logger.info(f"Label removida: {label_to_remove}")
                    except Exception as e:
                        logger.warning(
                            f"Não foi possível remover a label '{label_to_remove}': {e}"
                        )
                else:
                    logger.debug(
                        f"Label '{label_to_remove}' não estava presente na issue, ignorando remoção."
                    )

    await asyncio.to_thread(_update_sync)


async def get_issue_details(issue_number: int) -> dict:
    """
    Recupera os detalhes de uma issue específica (título, corpo).
    Necessário para obter os dados originais antes de salvar no Neo4j.
    """

    def _get_sync():
        issue = _get_issue_sync(issue_number)
        # Fetch comments to extract AI analysis details
        comments = [
            {
                "body": c.body,
                "created_at": c.created_at.isoformat(),
                "user": c.user.login,
            }
            for c in issue.get_comments()
        ]
        return {
            "number": issue.number,
            "title": issue.title,
            "body": issue.body,
            "html_url": issue.html_url,
            "created_at": issue.created_at.isoformat(),
            "comments": comments,
        }

    return await asyncio.to_thread(_get_sync)

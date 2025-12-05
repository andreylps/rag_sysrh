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
        issue = _get_issue_sync(issue_number)
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
        # HACK: Se a label for 'status:aguardando-validacao', buscamos também 'status:aguardando-review-tecnico'
        # para que o endpoint de backlog sirva para ambos os workbenches temporariamente.
        if label == "status:aguardando-validacao":
            # Nota: get_issues(labels=[...]) faz AND. Para fazer OR, precisamos fazer duas chamadas ou não filtrar por label na query e filtrar no python.
            # Como PyGithub não suporta OR nativo facilmente sem search query, vamos fazer duas chamadas se for esse caso especial.
            pass

        if label == "status:aguardando-validacao":
            issues_paginated = list(
                repo.get_issues(
                    state=state,
                    labels=["status:aguardando-validacao"],
                    sort="created",
                    direction="asc",
                )
            )
            issues_paginated += list(
                repo.get_issues(
                    state=state,
                    labels=["status:aguardando-review-tecnico"],
                    sort="created",
                    direction="asc",
                )
            )
            issues_paginated += list(
                repo.get_issues(
                    state=state,
                    labels=["status:aguardando-validacao-rcm"],
                    sort="created",
                    direction="asc",
                )
            )
            # --- CORREÇÃO INSERIDA AQUI ---
            issues_paginated += list(
                repo.get_issues(
                    state=state,
                    labels=[
                        "status:aguardando-liberacao-dev"
                    ],  # Adiciona a nova label do fluxo rápido
                    sort="created",
                    direction="asc",
                )
            )
            # ------------------------------
        else:
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

        # Remove duplicatas causadas pelas múltiplas chamadas (caso uma issue tenha mais de uma das labels buscadas)
        # Usa um dicionário para garantir unicidade pelo número da issue
        unique_issues_map = {issue["number"]: issue for issue in cleaned_issues}
        unique_cleaned_issues = list(unique_issues_map.values())

        logger.info(
            f"Encontradas {len(unique_cleaned_issues)} issues válidas (após remover duplicatas)."
        )
        return unique_cleaned_issues

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
            current_labels = [lbl.name for lbl in issue.labels]
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
        rcm_draft = None

        # 0. PRIORIDADE MÁXIMA: RCM Revisada pela IA (Pós-Feedback)
        for c in reversed(comments):
            if c["body"] and "## 🤖 RCM Revisada pela IA (Pós-Feedback)" in c["body"]:
                try:
                    parts = c["body"].split("## 🤖 RCM Revisada pela IA (Pós-Feedback)")
                    if len(parts) >= 2:
                        rcm_draft = parts[1].strip()
                        break
                except Exception:
                    pass

        # 1. Tenta encontrar a última versão validada pelo analista (para continuação)
        if not rcm_draft:
            for c in reversed(comments):
                if c["body"] and "## ✅ RCM Validada pelo Analista" in c["body"]:
                    # Extrai o conteúdo entre os separadores ---
                    try:
                        parts = c["body"].split("---")
                        if len(parts) >= 3:
                            rcm_draft = parts[1].strip()
                            break
                    except Exception:
                        pass

        # 2. Se não achar, pega o rascunho original da IA
        if not rcm_draft:
            for c in comments:
                if (
                    c["body"]
                    and "### 📋 Rascunho Preliminar de RCM (Gerado por IA)" in c["body"]
                ):
                    rcm_draft = c["body"]
                    break

        return {
            "number": issue.number,
            "title": issue.title,
            "body": issue.body,
            "html_url": issue.html_url,
            "created_at": issue.created_at.isoformat(),
            "comments": comments,
            "rcm_draft": rcm_draft,
            # Adiciona as labels também, pois o frontend precisa delas para decidir qual modo exibir
            "labels": [lbl.name for lbl in issue.labels],
        }

    return await asyncio.to_thread(_get_sync)


async def get_issue_change_report(issue_number: int) -> str | None:
    """
    Busca o comentário do 'Relatório de Mudanças' postado pelo Agente Dev.
    Retorna o corpo do comentário ou None se não encontrar.
    """

    def _get_sync():
        issue = _get_issue_sync(issue_number)
        # Itera sobre os comentários do mais recente para o mais antigo
        for comment in issue.get_comments().reversed:
            if (
                comment.body
                and "### 📝 Relatório de Mudanças (Arquivos Afetados)" in comment.body
            ):
                return comment.body
        return None

    return await asyncio.to_thread(_get_sync)


async def close_issue(issue_number: int) -> None:
    """
    Fecha uma issue no GitHub.
    """

    def _close_sync():
        issue = _get_issue_sync(issue_number)
        issue.edit(state="closed")
        logger.info(f"Issue #{issue_number} fechada com sucesso.")

    await asyncio.to_thread(_close_sync)


async def search_closed_issues(query: str, limit: int = 50) -> list[dict]:
    """
    Busca issues fechadas no GitHub usando uma query de pesquisa.
    Útil para histórico.
    """

    def _search_sync():
        g = get_github_client()
        # A query deve incluir o repositório
        # Ex: repo:owner/repo is:issue is:closed label:foo

        # Se a query não tiver 'repo:', adicionamos automaticamente
        final_query = query
        if "repo:" not in final_query:
            # Precisamos do full name (owner/repo) para a busca global,
            # mas se get_repo_name retornar apenas o nome do repo, pode falhar se não tiver o owner.
            # Vamos assumir que get_repo_name retorna o que está no .env.
            # Se for apenas 'RAG_SYSRH', a busca pode ser ampla demais ou falhar.
            # Melhor abordagem: buscar no repo específico objeto se possível, mas search_issues é global.
            # Vamos tentar pegar o full_name do repo objeto.
            repo = g.get_repo(get_repo_name())
            final_query = f"repo:{repo.full_name} {query}"

        logger.info(
            f"Buscando issues fechadas com query: '{final_query}' (Limit: {limit})"
        )

        issues_paginated = g.search_issues(final_query)

        cleaned_issues = []
        for issue in issues_paginated:
            if len(cleaned_issues) >= limit:
                break

            cleaned_issues.append(
                {
                    "github_id": issue.id,
                    "number": issue.number,
                    "title": issue.title,
                    "html_url": issue.html_url,
                    "created_at": issue.created_at.isoformat(),
                    "closed_at": issue.closed_at.isoformat()
                    if issue.closed_at
                    else None,
                    "labels": [lbl.name for lbl in issue.labels],
                    "state": issue.state,
                }
            )

        logger.info(f"Encontradas {len(cleaned_issues)} issues no histórico.")
        return cleaned_issues

    return await asyncio.to_thread(_search_sync)


async def search_issues_generic(query: str) -> list[dict]:
    """
    Busca issues no GitHub usando uma query genérica.
    Wrapper para search_closed_issues mas com nome mais apropriado para uso geral.
    """
    return await search_closed_issues(query)


async def count_issues_by_label(label: str, state: str = "open") -> int:
    """
    Conta o número de issues com uma determinada label e estado.
    Usa a propriedade totalCount para eficiência.
    """

    def _count_sync():
        g = get_github_client()
        repo_name = get_repo_name()
        repo = g.get_repo(repo_name)
        return repo.get_issues(state=state, labels=[label]).totalCount

    return await asyncio.to_thread(_count_sync)


async def upload_file_to_repo(
    local_file_path: str, target_path: str, commit_message: str
) -> str:
    """
    Faz upload de um arquivo para o repositório.
    Retorna a URL HTML do arquivo no GitHub.
    """

    def _upload_sync():
        g = get_github_client()
        repo_name = get_repo_name()
        repo = g.get_repo(repo_name)

        with open(local_file_path, "rb") as f:
            content = f.read()

        try:
            # Tenta pegar o arquivo existente para atualizar (sha)
            contents = repo.get_contents(target_path)
            repo.update_file(
                path=target_path,
                message=commit_message,
                content=content,
                sha=contents.sha,
            )
            logger.info(f"Arquivo atualizado no repo: {target_path}")
        except Exception:
            # Se não existir, cria um novo
            repo.create_file(
                path=target_path,
                message=commit_message,
                content=content,
            )
            logger.info(f"Arquivo criado no repo: {target_path}")

        # Retorna a URL para visualização
        # Ex: https://github.com/owner/repo/blob/main/path/to/file
        # Podemos construir ou pegar do commit, mas vamos construir para ser rápido
        # Assumindo branch 'main' ou 'master'. O ideal seria pegar a default branch.
        branch = repo.default_branch
        return f"https://github.com/{repo.full_name}/blob/{branch}/{target_path}"

    return await asyncio.to_thread(_upload_sync)


async def get_issue_events(issue_number: int) -> list[dict]:
    """
    Retorna a lista de eventos de uma issue (ex: labeled, milestoned, renamed).
    Útil para detectar loops de status.
    """

    def _get_events_sync():
        issue = _get_issue_sync(issue_number)
        events = []
        for event in issue.get_events():
            events.append(
                {
                    "event": event.event,
                    "created_at": event.created_at.isoformat(),
                    "label": event.label.name if event.label else None,
                    "actor": event.actor.login if event.actor else None,
                }
            )
        return events

    return await asyncio.to_thread(_get_events_sync)

import logging
import re
from typing import List

from fastapi import APIRouter, HTTPException

from src.services.file_system_service import read_file_content
from src.services.github_service import (  # Adicionado
    get_issue_change_report,
    list_issues_by_label,
    search_closed_issues,
)

# Configuração de Logging
logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/{issue_number}/files", status_code=200)
async def get_review_files(issue_number: int):
    """
    Busca o relatório de mudanças do Agente Dev e retorna o conteúdo dos arquivos modificados.
    """
    try:
        # 1. Buscar o relatório no GitHub
        report_body = await get_issue_change_report(issue_number)

        if not report_body:
            raise HTTPException(
                status_code=404, detail="Relatório de mudanças não encontrado na issue."
            )

        # 2. Parsear os caminhos dos arquivos
        # O formato esperado é: - [x] caminho/do/arquivo.py (Criado)
        # Regex para capturar o caminho entre [x] e (
        # Exemplo de linha: - [x] app/main.py (Modificado)
        # Regex: \- \[x\]\s+([^\s]+)

        file_paths = []
        lines = report_body.split("\n")
        for line in lines:
            match = re.search(r"- \[x\]\s+([^\s\(]+)", line)
            if match:
                path = match.group(1).strip()
                # Remove possíveis backticks ou aspas se o agente colocou
                path = path.replace("`", "").replace("'", "").replace('"', "")
                file_paths.append(path)

        if not file_paths:
            raise HTTPException(
                status_code=404,
                detail="Nenhum arquivo encontrado no relatório de mudanças.",
            )

        # 3. Ler o conteúdo dos arquivos
        files_data = []
        for path in file_paths:
            try:
                content = read_file_content(path)
                files_data.append({"path": path, "content": content, "status": "ok"})
            except Exception as e:
                logger.warning(f"Erro ao ler arquivo '{path}' para revisão: {e}")
                files_data.append(
                    {
                        "path": path,
                        "content": f"Erro ao ler arquivo: {str(e)}",
                        "status": "error",
                    }
                )

        return files_data

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Erro ao buscar arquivos para revisão: {e}")
        raise HTTPException(
            status_code=500, detail=f"Erro interno ao processar revisão: {str(e)}"
        )


@router.get("/backlog", response_model=List[dict])
async def get_review_backlog():
    """
    Retorna a lista de issues que estão aguardando revisão técnica.
    Busca por issues com a label 'status:aguardando-review-tecnico'.
    """
    # A função list_issues_by_label já sabe buscar por uma label específica
    issues = await list_issues_by_label(label="status:aguardando-review-tecnico")
    return issues


@router.get("/history", response_model=List[dict])
async def get_review_history():
    """
    Retorna o histórico de issues revisadas (fechadas).
    Busca por issues fechadas que tiveram a label 'status:aguardando-review-tecnico'.
    """
    try:
        # Estratégia Abrangente:
        # O usuário relatou que issues fechadas (como a #22) não aparecem.
        # A issue #22 não tem a label 'status:deploy-realizado' nem 'status:aguardando-review-tecnico'.
        # Para garantir que o histórico mostre todas as demandas finalizadas, vamos buscar todas as issues fechadas.
        # Opcionalmente, poderíamos filtrar por labels de "tipo" se quiséssemos ser mais específicos,
        # mas "Histórico de Revisões" pode implicar "Histórico de Entregas".

        query = "is:issue is:closed"
        issues = await search_closed_issues(query=query, limit=50)

        # Ordenar por data de fechamento decrescente
        sorted_issues = sorted(
            issues,
            key=lambda x: x["closed_at"] or x.get("updated_at") or "",
            reverse=True,
        )

        return list(sorted_issues)
    except Exception as e:
        logger.error(f"Erro ao buscar histórico de revisão: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Falha ao buscar histórico: {str(e)}",
        )


@router.post("/{issue_number}/deploy", status_code=200)
async def deploy_issue(issue_number: int):
    """
    Finaliza o ciclo de desenvolvimento:
    1. Posta comentário de deploy.
    2. Remove label de revisão.
    3. Fecha a issue.
    """
    try:
        from src.services.github_service import (
            post_comment,
            update_issue_labels,
        )

        logger.info(f"Iniciando deploy para issue #{issue_number}...")

        # 1. Postar comentário final
        await post_comment(
            issue_number=issue_number,
            body="🚀 **Deploy Realizado com Sucesso!**\n\nAs alterações foram revisadas tecnicamente e implantadas em produção.",
        )

        # 2. Atualizar Labels
        await update_issue_labels(
            issue_number=issue_number,
            remove_labels=["status:aguardando-review-tecnico"],
            add_labels=["status:aceite-homologacao"],
        )

        # 3. Fechar a Issue (REMOVIDO: Issue deve permanecer aberta para homologação)
        # await close_issue(issue_number=issue_number)

        return {
            "status": "success",
            "message": "Issue atualizada para aceite de homologação.",
        }

    except Exception as e:
        logger.error(f"Erro ao realizar deploy da issue #{issue_number}: {e}")
        raise HTTPException(
            status_code=500, detail=f"Erro ao realizar deploy: {str(e)}"
        )


@router.post("/{issue_number}/homologate", status_code=200)
async def homologate_issue(issue_number: int):
    """
    Realiza a homologação da issue:
    1. Remove label 'status:aceite-homologacao'.
    2. Adiciona label 'status:homologado'.
    3. Fecha a issue.
    """
    try:
        from src.services.github_service import (
            close_issue,
            post_comment,
            update_issue_labels,
        )

        logger.info(f"Iniciando homologação para issue #{issue_number}...")

        # 1. Postar comentário
        await post_comment(
            issue_number=issue_number,
            body="✅ **Homologação Realizada!**\n\nO usuário confirmou a homologação e a issue foi encerrada.",
        )

        # 2. Atualizar Labels
        await update_issue_labels(
            issue_number=issue_number,
            remove_labels=["status:aceite-homologacao"],
            add_labels=["status:homologado"],
        )

        # 3. Fechar a Issue
        await close_issue(issue_number=issue_number)

        return {
            "status": "success",
            "message": "Issue homologada e fechada com sucesso.",
        }

    except Exception as e:
        logger.error(f"Erro ao homologar issue #{issue_number}: {e}")
        raise HTTPException(
            status_code=500, detail=f"Erro ao homologar issue: {str(e)}"
        )

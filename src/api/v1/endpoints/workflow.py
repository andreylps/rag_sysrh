import logging

from fastapi import APIRouter, HTTPException, Path
from pydantic import BaseModel

from src.services.github_service import post_comment, update_issue_labels

router = APIRouter()
logger = logging.getLogger(__name__)


class FastTrackReleaseResponse(BaseModel):
    message: str
    issue_number: int


@router.post(
    "/{issue_number}/release-fast-track", response_model=FastTrackReleaseResponse
)
async def release_fast_track(
    issue_number: int = Path(..., title="The ID of the issue to release", ge=1),
):
    """
    Libera uma issue para o fluxo de desenvolvimento rápido (Fast Track).

    Ações:
    1. Posta um comentário no GitHub informando a liberação.
    2. Remove a label 'status:aguardando-liberacao-dev'.
    3. Adiciona a label 'status:pronto-para-dev'.
    """
    try:
        logger.info(f"Iniciando liberação Fast Track para issue #{issue_number}")

        # Ação 1: Comentário no GitHub
        comment_body = "🚀 **Fast Track Liberado**\n\nDemanda de correção/esforço aprovada pelo analista para início imediato. O fluxo de RCM foi dispensado."
        await post_comment(issue_number, comment_body)

        # Ação 2: Mover Fluxo (Atualizar Labels)
        await update_issue_labels(
            issue_number,
            remove_labels=["status:aguardando-liberacao-dev"],
            add_labels=["status:pronto-para-dev", "status:fast-track-aprovado"],
        )

        logger.info(f"Issue #{issue_number} liberada com sucesso para Fast Track.")

        return FastTrackReleaseResponse(
            message="Fast Track liberado com sucesso.", issue_number=issue_number
        )

    except Exception as e:
        logger.error(f"Erro ao liberar Fast Track para issue #{issue_number}: {e}")
        raise HTTPException(
            status_code=500, detail=f"Erro ao processar liberação Fast Track: {str(e)}"
        )

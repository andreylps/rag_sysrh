from datetime import datetime

from fastapi import APIRouter, HTTPException

from src.services.github_service import count_issues_by_label

router = APIRouter()


@router.get("/workflow-stats")
async def get_workflow_stats():
    """
    Retorna estatísticas do fluxo de trabalho (contagem de issues por etapa).
    """
    try:
        # Contagem paralela (embora o count_issues_by_label use thread, podemos iniciar todos?)
        # Como count_issues_by_label é async (await asyncio.to_thread), podemos chamá-los sequencialmente
        # ou usar asyncio.gather para paralelizar de verdade se quisermos.
        # Para simplicidade e evitar rate limit agressivo, vamos sequencial.

        validation_count_standard = await count_issues_by_label(
            "status:aguardando-validacao"
        )
        validation_count_rcm = await count_issues_by_label(
            "status:aguardando-validacao-rcm"
        )
        validation_count = validation_count_standard + validation_count_rcm
        fast_track_count = await count_issues_by_label(
            "status:aguardando-liberacao-dev"
        )
        # "in_factory" são issues prontas para dev (na fila) ou em progresso?
        # O prompt diz: factory_queue: status:pronto-para-dev (Issues que a IA ainda não pegou)
        factory_count = await count_issues_by_label("status:pronto-para-dev")
        review_count = await count_issues_by_label("status:aguardando-review-tecnico")

        total_active = (
            validation_count + fast_track_count + factory_count + review_count
        )

        return {
            "validation": validation_count,
            "fast_track": fast_track_count,
            "in_factory": factory_count,
            "review": review_count,
            "total_active": total_active,
            "timestamp": datetime.now().isoformat(),
        }
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Erro ao buscar estatísticas: {str(e)}"
        )

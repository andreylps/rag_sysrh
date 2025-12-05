from typing import Any

from fastapi import APIRouter, BackgroundTasks

from src.services.commercial_service import commercial_service

router = APIRouter()


@router.post("/scan", response_model=dict[str, str])
async def trigger_scan(background_tasks: BackgroundTasks):
    """
    Inicia uma varredura do código fonte em busca de oportunidades comerciais.
    A varredura é executada em background.
    """
    background_tasks.add_task(commercial_service.scan_for_opportunities)
    return {
        "message": "Varredura iniciada em background. Verifique /opportunities em breve."
    }


@router.get("/opportunities", response_model=list[dict[str, Any]])
async def get_opportunities():
    """
    Retorna a lista de oportunidades de negócio identificadas pelo Sniper Agent.
    """
    return commercial_service.get_opportunities()

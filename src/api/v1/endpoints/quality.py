from typing import List

from fastapi import APIRouter, status

from src.core.quality_alerts import get_all_alerts
from src.services.quality_service import get_qa_dashboard_metrics

router = APIRouter()


@router.get("/alerts", response_model=List[dict])
async def get_alerts():
    """
    Retorna a lista de alertas ativos de qualidade.
    """
    return get_all_alerts()


@router.get("/metrics", status_code=status.HTTP_200_OK)
async def get_metrics():
    """
    Retorna as métricas e KPIs para o dashboard de qualidade.
    """
    return await get_qa_dashboard_metrics()

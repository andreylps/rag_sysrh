from fastapi import APIRouter, status

from src.core.quality_alerts import get_all_alerts
from src.services.quality_service import get_qa_dashboard_metrics

router = APIRouter()


@router.get("/alerts", response_model=list[dict])
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


@router.get("/iso-indicators", status_code=status.HTTP_200_OK)
async def get_iso_metrics():
    """
    Retorna indicadores detalhados baseados nas normas ISO (12207, 25000, 27001).
    """
    from src.services.quality_service import get_iso_indicators

    return await get_iso_indicators()


@router.post("/agent/monthly-report", status_code=status.HTTP_200_OK)
async def generate_monthly_report():
    """
    Gera o Relatório Mensal de Qualidade usando o QualityAgent.
    """
    from src.agents.quality_agent import quality_agent
    from src.services.quality_service import get_iso_indicators

    indicators = await get_iso_indicators()
    report = await quality_agent.generate_monthly_report(indicators)
    return {"report": report}

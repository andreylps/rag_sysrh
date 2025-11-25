from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from src.rag_sysrh.services.bi_service import get_dashboard_stats
from src.rag_sysrh.services.billing_service import BillingService
from src.rag_sysrh.services.strategic_service import StrategicService

router = APIRouter()
strategic_service = StrategicService()
billing_service = BillingService()


class StrategicAnalysisRequest(BaseModel):
    period: str = "30d"
    team: str = "Todos"
    client: str = "Todos"


@router.get("/stats")
async def get_stats():
    """
    Retorna estatísticas gerais do dashboard (KPIs básicos).
    """
    return get_dashboard_stats()


@router.post("/strategic/analyze")
async def analyze_strategic(request: StrategicAnalysisRequest):
    """
    Executa a análise estratégica completa (KPIs avançados + Narrativa IA).
    """
    try:
        return strategic_service.analyze(request.period, request.team, request.client)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/billing/report")
async def get_billing_report():
    """
    Retorna o relatório de faturamento e rentabilidade.
    """
    try:
        return billing_service.get_billing_report()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

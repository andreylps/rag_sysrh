import logging
from typing import Any

from src.rag_sysrh.agents.strategic_manager import StrategicManagerAgent
from src.rag_sysrh.services.strategic_data_service import StrategicDataService

logger = logging.getLogger(__name__)


class StrategicService:
    def __init__(self) -> None:
        self.agent = StrategicManagerAgent()
        self.data_service = StrategicDataService()

    def analyze(
        self, period: str = "30d", team: str = "Todos", client: str = "Todos"
    ) -> dict[str, Any]:
        """
        Realiza a análise estratégica completa.
        """
        # 1. Coleta de Dados Operacionais
        health_scan = self.data_service.get_operational_health_scan(period)

        # 2. Análise de Tendência (Lead Time)
        trend = self.data_service.get_lead_time_trend(team, client, period)

        # 3. Análise de Gargalos
        bottlenecks = self.data_service.get_bottleneck_analysis(team, client)

        # 4. Motivos de Recusa
        rejections = self.data_service.get_rejection_reasons_summary(team, client)

        # 5. KPIs Financeiros (Estimativa)
        financials = self.data_service.get_financial_kpis(client, period)

        # 6. Análise da IA (Narrativa)
        # Prepara o contexto para o LLM
        context = {
            "kpis": health_scan["kpis"],
            "trend": trend,
            "bottlenecks": bottlenecks,
            "rejections": rejections,
            "financials": financials,
            "period": period,
            "team": team,
            "client": client,
        }

        # Gera a narrativa estratégica
        narrative = self.agent.run_strategic_analysis(context)

        return {
            "kpis": health_scan["kpis"],
            "heatmap": health_scan["heatmap_data"],
            "trend": trend,
            "bottlenecks": bottlenecks,
            "rejections": rejections,
            "financials": financials,
            "narrative": narrative.dict(),
        }

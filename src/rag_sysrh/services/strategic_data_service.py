import logging
from typing import Any, Dict, List

from src.rag_sysrh.neo4j_connection import get_graph

logger = logging.getLogger(__name__)


class StrategicDataService:
    """
    Serviço de Inteligência de Dados Estratégicos.
    Executa queries Cypher complexas no Neo4j para extrair métricas operacionais.
    """

    def __init__(self):
        self.graph = get_graph()

    def get_operational_health_scan(self, period: str = "30d") -> Dict[str, Any]:
        """Retorna KPIs globais e dados para heatmap baseados em dados reais do Neo4j."""
        # Filtro de período (placeholder - implementar lógica real de data se necessário)
        # Para MVP, vamos considerar todos os dados

        # KPI: Total de Demandas e Taxa de Entrega
        query_kpis = """
        MATCH (s:Solicitacao)
        RETURN 
            count(s) AS total_demandas,
            sum(CASE WHEN toLower(s.status) = 'concluido' THEN 1 ELSE 0 END) AS entregues
        """
        result_kpis = self.graph.query(query_kpis)
        total_demandas = result_kpis[0]["total_demandas"] if result_kpis else 0
        entregues = result_kpis[0]["entregues"] if result_kpis else 0
        taxa_entrega = (entregues / total_demandas * 100) if total_demandas > 0 else 0

        # KPI: Lead Time Médio (Mockado por enquanto, pois falta data de conclusão no grafo)
        # Idealmente: avg(duration.inDays(s.data_criacao, s.data_conclusao))
        lead_time_medio = 5.5  # Valor placeholder

        # Dados para Heatmap (Eficiência por Time x Cliente)
        # Mockado pois não temos definição clara de Time no grafo ainda
        heatmap_data = [
            {
                "time_extraido": "Time A",
                "cliente_extraido": "Cliente X",
                "eficiencia": 85.0,
            },
            {
                "time_extraido": "Time B",
                "cliente_extraido": "Cliente Y",
                "eficiencia": 92.5,
            },
            {
                "time_extraido": "Time A",
                "cliente_extraido": "Cliente Y",
                "eficiencia": 78.0,
            },
        ]

        return {
            "kpis": {
                "total_demandas": total_demandas,
                "entregues": entregues,
                "taxa_entrega": round(taxa_entrega, 1),
                "lead_time_medio": round(lead_time_medio, 1),
            },
            "heatmap_data": heatmap_data,
        }

    def get_lead_time_trend(
        self, team: str, client: str, period: str = "90d"
    ) -> List[Dict]:
        """Retorna série temporal de Lead Time semanal (Mockado)."""
        # Mock para demonstração do gráfico de linha
        return [
            {"semana": "2023-10-01", "lead_time": 4.2},
            {"semana": "2023-10-08", "lead_time": 5.1},
            {"semana": "2023-10-15", "lead_time": 4.8},
            {"semana": "2023-10-22", "lead_time": 6.0},
            {"semana": "2023-10-29", "lead_time": 5.5},
        ]

    def get_bottleneck_analysis(self, team: str, client: str) -> List[Dict]:
        """Retorna tempo médio em cada etapa (Mockado)."""
        # Mock para demonstração do gráfico de barras
        return [
            {"etapa": "Análise", "tempo_medio_dias": 3},
            {"etapa": "Desenvolvimento", "tempo_medio_dias": 7},
            {"etapa": "Testes", "tempo_medio_dias": 4},
            {"etapa": "Validação", "tempo_medio_dias": 2},
        ]

    def get_rejection_reasons_summary(self, team: str, client: str) -> List[Dict]:
        """Retorna sumário de motivos de recusa (Mockado)."""
        # Mock para demonstração
        return [
            {"motivo": "Especificação Incompleta", "quantidade": 12},
            {"motivo": "Duplicado", "quantidade": 5},
            {"motivo": "Inviabilidade Técnica", "quantidade": 3},
        ]

    def get_financial_kpis(self, client: str, period: str) -> Dict[str, float]:
        """Calcula KPIs financeiros baseado no esforço real registrado no Neo4j."""
        # Busca o esforço total de solicitações concluídas
        query = """
        MATCH (s:Solicitacao)
        WHERE toLower(s.status) = 'concluido'
        RETURN sum(s.effort) AS esforco_total
        """
        result = self.graph.query(query)
        pf_total = (
            result[0]["esforco_total"]
            if result and result[0]["esforco_total"] is not None
            else 0
        )

        # Valor mockado por PF (poderia vir de um nó :Custo no futuro)
        valor_pf = 500.00
        faturamento_realizado = pf_total * valor_pf

        return {
            "faturamento_realizado": faturamento_realizado,
            "meta_faturamento": faturamento_realizado * 1.2,  # Meta 20% acima
        }

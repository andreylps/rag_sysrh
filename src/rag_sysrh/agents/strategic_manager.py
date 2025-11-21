from typing import Any, Dict

from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI
from pydantic import BaseModel, Field

from rag_sysrh.core.knowledge_base import get_contexto_organizacional_completo
from rag_sysrh.services.strategic_data_service import StrategicDataService


class AnaliseEstrategica(BaseModel):
    """Modelo de saída da análise estratégica do agente."""

    alerta_risco: str = Field(
        ..., description="Manchete do principal risco identificado"
    )
    evidencia_dados: str = Field(
        ..., description="Dados que sustentam o alerta (Causa Raiz)"
    )
    analise_preditiva: str = Field(
        ..., description="O que acontecerá se nada for feito"
    )
    plano_acao: str = Field(..., description="Lista de ações recomendadas (Markdown)")


class StrategicManagerAgent:
    """
    Agente Gerente Estratégico (GerenteAI).
    Orquestra a análise de dados e geração de insights.
    """

    def __init__(self):
        self.data_service = StrategicDataService()
        self.llm = ChatOpenAI(
            model="gpt-4o", temperature=0.2
        )  # Baixa temperatura para análise sóbria

    def run_analysis(self, period: str, team: str, client: str) -> Dict[str, Any]:
        """
        Executa o ciclo completo de análise: Scan -> LLM -> Resultado.
        """
        # 1. Coleta de Dados (Scan)
        scan_data = self.data_service.get_operational_health_scan(period)
        bottlenecks = self.data_service.get_bottleneck_analysis(team, client)
        rejections = self.data_service.get_rejection_reasons_summary(team, client)
        financials = (
            self.data_service.get_financial_kpis(client, period)
            if client and client != "Todos"
            else {}
        )

        # Prepara contexto para o LLM
        contexto_dados = f"""
        KPIs Globais (Período: {period}):
        - Total Demandas: {scan_data["kpis"]["total_demandas"]}
        - Entregues: {scan_data["kpis"]["entregues"]}
        - Taxa de Entrega: {scan_data["kpis"]["taxa_entrega"]}%
        - Lead Time Médio: {scan_data["kpis"]["lead_time_medio"]} dias
        
        Filtros Aplicados: Time={team}, Cliente={client}
        
        Análise de Gargalos (Tempo por etapa):
        {bottlenecks}
        
        Principais Motivos de Recusa/Atrito:
        {rejections}
        
        Dados Financeiros (Estimado):
        {financials}
        """

        # 2. Análise Cognitiva (LLM)
        analise = self._generate_strategic_narrative(contexto_dados)

        # 3. Retorno Estruturado
        return {
            "data": {
                "scan": scan_data,
                "bottlenecks": bottlenecks,
                "rejections": rejections,
                "financials": financials,
            },
            "analysis": analise,
        }

    def _generate_strategic_narrative(self, context: str) -> AnaliseEstrategica:
        """Gera a narrativa estratégica usando o LLM."""

        contexto_org = get_contexto_organizacional_completo()

        prompt = ChatPromptTemplate.from_messages(
            [
                (
                    "system",
                    f"""Você é o Head de Estratégia Operacional do SYSRH.
            Sua função é analisar os dados operacionais e gerar insights de negócio críticos.
            
            {contexto_org}
            
            Diretrizes:
            1. Seja direto e executivo. Foque em impacto financeiro e de prazo.
            2. Identifique anomalias. Se a taxa de entrega for baixa (<50%) ou Lead Time alto, isso é um problema.
            3. Conecte os pontos: Gargalo em 'Validação' + Recusa por 'Especificação' = Problema de Requisitos.
            4. Regra Crítica: Cliente ALESC tem prioridade máxima. Bugs são tratados como evolutivas.
            
            Gere uma análise estruturada contendo: Alerta, Evidência, Predição e Plano de Ação.
            """,
                ),
                ("user", "Analise os seguintes dados operacionais:\n{context}"),
            ]
        )

        chain = prompt | self.llm.with_structured_output(AnaliseEstrategica)
        return chain.invoke({"context": context})

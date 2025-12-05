import json
import logging
import os
from typing import Any

from openai import OpenAI

# Configura o logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class CommercialAgent:
    """
    Agente responsável por analisar indicadores comerciais e gerar insights estratégicos.
    """

    def __init__(self):
        self.client = None
        self.system_prompt = """
        Você é um Diretor Comercial Sênior (CSO) especializado em Fábricas de Software e Consultorias de TI, com foco no mercado de Portugal e Europa.
        Sua missão é analisar os indicadores financeiros e de vendas da empresa e fornecer uma análise crítica, estratégica e acionável.

        **Contexto do Negócio:**
        - Venda de serviços intelectuais, projetos de longo prazo e receitas recorrentes (squads, manutenção).
        - Ciclos de vendas longos.
        - Custo de pré-venda elevado.

        **Seus Objetivos:**
        1.  **Diagnóstico:** Identificar gargalos no funil de vendas, riscos de churn ou ineficiências financeiras (ex: CAC alto vs LTV baixo).
        2.  **Previsão:** Alertar sobre tendências preocupantes (ex: queda no backlog).
        3.  **Ação:** Sugerir ações corretivas práticas (ex: "Focar em upsell na base atual devido ao alto custo de aquisição").

        **Formato da Resposta:**
        Retorne SEMPRE um JSON com a seguinte estrutura:
        {
            "resumo_executivo": "Uma visão geral curta e direta do estado atual.",
            "pontos_fortes": ["Lista de 2-3 pontos positivos identificados"],
            "pontos_atencao": ["Lista de 2-3 pontos críticos que exigem cuidado"],
            "analise_detalhada": "Uma análise mais profunda correlacionando os indicadores (ex: explicar por que o Win Rate está baixo apesar de muitos leads).",
            "recomendacoes_acao": ["Lista de 3 ações práticas sugeridas para o próximo trimestre"]
        }
        """

    def analyze_indicators(self, indicators: dict[str, Any]) -> dict[str, Any]:
        """
        Analisa os indicadores fornecidos e retorna insights.
        """
        user_prompt = f"""
        Analise os seguintes indicadores comerciais da nossa Fábrica de Software:

        **1. Receita e Vendas:**
        - MRR (Receita Recorrente): {indicators.get("mrr")}
        - TCV (Total Contract Value): {indicators.get("tcv")}
        - Ticket Médio: {indicators.get("ticket_medio")}
        - Backlog de Receita: {indicators.get("revenue_backlog")}

        **2. Eficiência do Funil:**
        - Taxa de Conversão (Lead to Deal): {indicators.get("conversion_rate")}
        - Win Rate (Propostas Ganhas): {indicators.get("win_rate")}
        - Ciclo de Vendas Médio: {indicators.get("sales_cycle")}
        - Taxa de Qualificação: {indicators.get("lead_qualification_rate")}

        **3. Custos e Rentabilidade:**
        - CAC (Custo de Aquisição): {indicators.get("cac")}
        - LTV (Lifetime Value): {indicators.get("ltv")}
        - Margem Comercial Média: {indicators.get("margin")}

        **4. Retenção e Expansão:**
        - Churn Rate: {indicators.get("churn_rate")}
        - NPS: {indicators.get("nps")}
        """

        try:
            if not self.client:
                self.client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

            response = self.client.chat.completions.create(
                model="gpt-4o",
                messages=[
                    {"role": "system", "content": self.system_prompt},
                    {"role": "user", "content": user_prompt},
                ],
                response_format={"type": "json_object"},
                temperature=0.7,
            )

            content = response.choices[0].message.content
            return json.loads(content)

        except Exception as e:
            logger.error(f"Erro na análise comercial: {e}")
            return {
                "resumo_executivo": "Não foi possível gerar a análise no momento.",
                "pontos_fortes": [],
                "pontos_atencao": ["Erro de conexão com o Agente IA"],
                "analise_detalhada": f"Detalhe do erro: {e!s}",
                "recomendacoes_acao": ["Verificar logs do sistema"],
            }

import logging
from typing import Literal

from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI

from src.services.scrum_master_service import scrum_master_service

logger = logging.getLogger(__name__)


class ScrumAgent:
    """
    Agente Scrum Master (IA) responsável por gerar análises qualitativas
    sobre o processo, métricas e saúde do time.
    """

    def __init__(self) -> None:
        self.llm = ChatOpenAI(model="gpt-4-turbo", temperature=0.3)

    async def generate_report(
        self,
        report_type: Literal["review", "retro", "planning"],
        sprint_id: str | None = None,
    ) -> str:
        """
        Gera um relatório textual baseado nas métricas atuais.
        """
        logger.info("Gerando relatório Scrum (%s)...", report_type)

        # 1. Coletar Dados
        metrics = await scrum_master_service.calculate_advanced_metrics(sprint_id)
        sprint_stats = await scrum_master_service.get_current_sprint_stats()

        # Contexto para o LLM
        context = f"""
        MÉTRICAS DE FLUXO:
        - Lead Time Médio: {metrics["flow"]["lead_time_avg_days"]} dias
        - Cycle Time Médio: {metrics["flow"]["cycle_time_avg_days"]} dias
        - WIP Atual: {metrics["flow"]["wip"]} itens
        - Throughput: {metrics["flow"]["throughput_sprint"]} itens entregues

        MÉTRICAS DE QUALIDADE:
        - Bugs na Sprint: {metrics["quality"]["bugs_count"]}
        - Itens com Retrabalho: {metrics["quality"]["rework_count"]} (
            {metrics["quality"]["rework_rate"]}%)

        SAÚDE DO TIME:
        - Bloqueios: {metrics["health"]["blockers_count"]}
        - Moral (0-5): {metrics["health"]["team_morale"]}

        PREVISIBILIDADE:
        - Itens Não Planejados: {metrics["predictability"]["unplanned_items"]}

        ESTADO DA SPRINT:
        - Total PF: {sprint_stats["total_pf"]}
        - Entregue PF: {sprint_stats["completed_pf"]}
        - Issues Totais: {sprint_stats["issues_total"]}
        - Issues Fechadas: {sprint_stats["issues_done"]}
        """

        # 2. Selecionar Prompt
        # 2. Selecionar Prompt
        if report_type == "review":
            prompt_template = """
            Você é um Scrum Master Sênior e Analista de Dados. Gere um relatório de
            **Sprint Review** executivo e baseado em evidências.

            DADOS DA SPRINT:
            {context}

            ESTRUTURA DO RELATÓRIO (Markdown):
            # 🏁 Sprint Review Report
            ## 1. Resumo Executivo
            (Sintetize o valor entregue. A meta foi atingida? Se houve desvio, explique
            o porquê com dados.)

            ## 2. Análise de Eficiência (Fluxo)
            - **Lead Time & Cycle Time**: Analise se o tempo de entrega está dentro do
              esperado. Compare Cycle Time vs Lead Time para identificar gargalos de
              espera.
            - **Throughput**: A entrega (PF/Itens) foi consistente com a capacidade?

            ## 3. Qualidade & Riscos
            - **Taxa de Retrabalho**: Se > 10%, destaque como crítico. O que causou?
            - **Bugs**: Impactaram a entrega?

            ## 4. Próximos Passos
            (Recomendações estratégicas para a próxima iteração baseadas nos dados
            acima)
            """

        elif report_type == "retro":
            prompt_template = """
            Você é um Agile Coach Especialista em Melhoria Contínua. Gere um relatório
            de **Sprint Retrospective** focado em causa raiz e ações práticas.

            DADOS DA SPRINT:
            {context}

            ESTRUTURA DO RELATÓRIO (Markdown):
            # 🔄 Sprint Retrospective
            ## 1. O que funcionou bem? (Keep)
            (Destaque métricas positivas. Ex: Baixo Lead Time, Zero Bugs, Moral Alta)

            ## 2. Pontos de Atenção (Fix)
            - **Gargalos**: Onde o fluxo parou? (Analise Aging WIP e Bloqueios)
            - **Qualidade**: Se houve retrabalho ou bugs, qual o padrão? (Ex: Falha de
              requisitos, testes insuficientes)
            - **Interrupções**: Analise o impacto dos itens não planejados.

            ## 3. Análise de Causa Raiz
            (Para cada ponto de atenção, proponha uma hipótese de causa raiz baseada
            nos dados. Evite generalismos.)

            ## 4. Plano de Ação (Try)
            (3 ações concretas, mensuráveis e com donos sugeridos para a próxima sprint)
            """

        elif report_type == "planning":
            prompt_template = """
            Você é um Scrum Master focado em Previsibilidade. Gere um relatório de
            **Sprint Planning** para orientar o time na definição da próxima meta.

            DADOS DA SPRINT ANTERIOR/ATUAL:
            {context}

            ESTRUTURA DO RELATÓRIO (Markdown):
            # 📅 Sprint Planning Guidance
            ## 1. Capacidade Recomendada
            (Baseado no Throughput e Velocity (PF) recentes, sugira uma capacidade
            segura e uma desafiadora.)

            ## 2. Foco de Melhoria (Kaizen)
            (Baseado na Retrospectiva, qual deve ser o foco técnico ou de processo
            desta sprint? Ex: Reduzir retrabalho, focar em testes)

            ## 3. Gestão de Riscos
            - **Itens Não Planejados**: Se alto na última sprint, sugira deixar um
              "buffer" de capacidade.
            - **SLA**: Se houve estouros, sugira priorização de itens antigos.
            """
        else:
            return "Tipo de relatório inválido."

        # 3. Gerar
        prompt = ChatPromptTemplate.from_template(prompt_template)
        chain = prompt | self.llm | StrOutputParser()

        return await chain.ainvoke({"context": context})


# Instância global
scrum_agent = ScrumAgent()

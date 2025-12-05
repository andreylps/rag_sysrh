import logging
from datetime import datetime
from pathlib import Path
from typing import Any

from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI

logger = logging.getLogger(__name__)

# Diretório para salvar procedimentos gerados
PROCEDURES_DIR = Path("data/Procedimentos")


class QualityAgent:
    """
    Agente de Qualidade (IA) responsável por gerar relatórios de melhoria contínua,
    análises baseadas em normas ISO e elaborar procedimentos operacionais.
    """

    def __init__(self) -> None:
        self.llm = ChatOpenAI(model="gpt-4-turbo", temperature=0.3)
        self._ensure_procedures_dir()

    def _ensure_procedures_dir(self) -> None:
        """Garante que o diretório de procedimentos exista."""
        PROCEDURES_DIR.mkdir(parents=True, exist_ok=True)

    async def generate_monthly_report(self, indicators: dict[str, Any]) -> str:
        """
        Gera um relatório mensal de qualidade e melhoria contínua baseado nos indicadores ISO.
        """
        logger.info("Gerando Relatório Mensal de Qualidade (ISO)...")

        # Contexto para o LLM
        context = self._format_indicators_context(indicators)

        prompt_template = """
        Você é um Gerente de Qualidade e Auditor Líder (ISO 9001, 27001, 12207).
        Sua tarefa é gerar um **Relatório Mensal de Melhoria Contínua** executivo e
        analítico.

        DADOS DO MÊS (INDICADORES ISO):
        {context}

        ESTRUTURA DO RELATÓRIO (Markdown):
        # 📊 Relatório Mensal de Qualidade & Melhoria Contínua

        ## 1. Resumo Executivo
        (Visão geral da saúde dos processos e produtos. Destaque 1 ponto forte e 1
        ponto crítico.)

        ## 2. Análise de Conformidade (ISO 12207 & 9001)
        - **Processos**: Analise a aderência aos processos. Se houver desvios, sugira
          correções.
        - **Documentação**: Avalie a qualidade documental.

        ## 3. Qualidade do Produto (ISO 25000)
        - **Confiabilidade & Segurança**: Analise bugs, vulnerabilidades e MTBF.
        - **Manutenibilidade**: Comente sobre a dívida técnica e complexidade.

        ## 4. Plano de Ação (PDCA)
        (Proponha 3 ações corretivas ou preventivas para o próximo ciclo, baseadas
        nos dados.)
        - **Ação 1**: [O que fazer] (Por que?)
        - **Ação 2**: ...
        - **Ação 3**: ...
        """

        prompt = ChatPromptTemplate.from_template(prompt_template)
        chain = prompt | self.llm | StrOutputParser()

        return await chain.ainvoke({"context": context})

    async def create_procedure(self, title: str, objective: str) -> str:
        """
        Gera um Procedimento Operacional Padrão (POP) e o salva na pasta de Procedimentos.

        Args:
            title: Título do procedimento.
            objective: Objetivo e escopo do procedimento.

        Returns:
            O caminho do arquivo gerado.
        """
        logger.info(f"Gerando Procedimento: {title}...")

        prompt_template = """
        Você é um Especialista em Processos e Qualidade (ISO 9001).
        Sua tarefa é elaborar um **Procedimento Operacional Padrão (POP)** detalhado e profissional.

        TÍTULO: {title}
        OBJETIVO: {objective}

        ESTRUTURA DO PROCEDIMENTO (Markdown):
        # {title}

        ## 1. Objetivo
        (Descreva o propósito deste procedimento)

        ## 2. Escopo
        (A quem e a que se aplica)

        ## 3. Responsabilidades
        (Quem faz o que)

        ## 4. Definições e Siglas
        (Se aplicável)

        ## 5. Descrição do Processo (Passo a Passo)
        (Use listas numeradas para descrever as etapas de forma clara e sequencial)

        ## 6. Referências Normativas
        (Cite ISO 9001, 27001 ou outras normas aplicáveis)

        ## 7. Histórico de Revisão
        | Versão | Data | Descrição | Autor |
        |---|---|---|---|
        | 1.0 | {date} | Criação Inicial | Agente de Qualidade |
        """

        prompt = ChatPromptTemplate.from_template(prompt_template)
        chain = prompt | self.llm | StrOutputParser()

        content = await chain.ainvoke(
            {
                "title": title,
                "objective": objective,
                "date": datetime.now().strftime("%Y-%m-%d"),
            }
        )

        # Sanitizar nome do arquivo
        safe_filename = "".join(
            c for c in title if c.isalnum() or c in (" ", "-", "_")
        ).strip()
        safe_filename = safe_filename.replace(" ", "_") + ".md"
        file_path = PROCEDURES_DIR / safe_filename

        try:
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(content)
            logger.info(f"Procedimento salvo em: {file_path}")
            return str(file_path)
        except Exception as e:
            logger.error(f"Erro ao salvar procedimento {file_path}: {e}")
            raise

    def _format_indicators_context(self, indicators: dict[str, Any]) -> str:
        """Formata os indicadores JSON para texto legível pelo LLM."""
        try:
            # Extração segura de métricas aninhadas
            process = indicators.get("process", {})
            product = indicators.get("product", {})
            security = indicators.get("security", {})

            return f"""
            === 1. PROCESSOS (ISO 12207/9001) ===
            - Conformidade de Processos: {process.get("compliance_rate", "N/A")}%
            - Não Conformidades: {process.get("non_conformities", 0)}
            - Maturidade (SPICE): Nível {process.get("maturity_level", "N/A")}

            === 2. PRODUTO (ISO 25000) ===
            - Cobertura Funcional: {product.get("functional_coverage", "N/A")}%
            - Bugs em Produção: {product.get("production_bugs", 0)}
            - Dívida Técnica: {product.get("technical_debt_ratio", "N/A")}%
            - MTBF: {product.get("mtbf_hours", "N/A")} horas

            === 3. SEGURANÇA (ISO 27001) ===
            - Vulnerabilidades Críticas: {security.get("critical_vulnerabilities", 0)}
            - Incidentes de Segurança: {security.get("security_incidents", 0)}
            - Riscos Tratados: {security.get("risk_mitigation_rate", "N/A")}%

            === 4. AUDITORIAS ===
            - Auditorias Realizadas: {indicators.get("audit", {}).get("total_audits", 0)}
            - Taxa de Correção de Gaps: {indicators.get("audit", {}).get("gap_correction_rate", "N/A")}%
            """
        except Exception:
            logger.exception("Erro ao formatar contexto para QualityAgent")
            return "Erro ao processar dados dos indicadores."


# Instância global
quality_agent = QualityAgent()

from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI

from rag_sysrh.core.knowledge_base import get_contexto_organizacional_completo
from rag_sysrh.engine.models import AvaliacaoRisco


class RiskAssessor:
    """
    Serviço responsável por avaliar o risco e complexidade técnica da solicitação.
    Utiliza LLM para preencher a rubrica de avaliação (1-5).
    """

    def __init__(self, model_name: str = "gpt-4o-mini"):
        self.llm = ChatOpenAI(model=model_name, temperature=0)

    def avaliar_risco(self, solicitacao: str, diagnostico: str) -> AvaliacaoRisco:
        """
        Avalia o risco da solicitação.
        """
        contexto_org = get_contexto_organizacional_completo()

        prompt = ChatPromptTemplate.from_messages(
            [
                (
                    "system",
                    f"""Você é um Especialista em Gestão de Risco de Software.
            
            {contexto_org}
            
            Avalie a solicitação e o diagnóstico técnico fornecidos.
            Atribua notas de 1 (Trivial) a 5 (Crítico) para os fatores de risco.
            
            IMPORTANTE: Considere as Regras de Exceção Críticas (ex: ALESC) ao avaliar a complexidade e impacto.
            """,
                ),
                ("user", "Solicitação: {solicitacao}\nDiagnóstico: {diagnostico}"),
            ]
        )

        chain = prompt | self.llm.with_structured_output(AvaliacaoRisco)
        return chain.invoke({"solicitacao": solicitacao, "diagnostico": diagnostico})

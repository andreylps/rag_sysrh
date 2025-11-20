import os
import sys
from pathlib import Path
from typing import TypedDict

import guardrails as gd  # type: ignore
from langchain_core.messages import HumanMessage  # type: ignore
from langchain_openai import ChatOpenAI  # type: ignore
from langgraph.graph import StateGraph  # type: ignore

# --- Solução para o ImportError ---
SRC_PATH = Path(__file__).resolve().parent.parent.parent
if str(SRC_PATH) not in sys.path:
    sys.path.append(str(SRC_PATH))

from rag_sysrh.analista_workflow import AnalistaWorkflow, RelatorioAnalise  # noqa: E402
from rag_sysrh.guardrails.rail_specs import rail_spec_topical  # noqa: E402
from rag_sysrh.main import get_tools  # noqa: E402

llm = ChatOpenAI(model=os.getenv("OPENAI_MODEL", "gpt-4o"), temperature=0)


class GuardedState(TypedDict):
    """Define o estado do workflow com guardrail."""

    solicitacao_original: str
    is_on_topic: bool
    final_report: RelatorioAnalise | str | None


# --- Nós do Grafo ---


def check_topicality_node(state: GuardedState) -> GuardedState:
    """
    Verifica se a pergunta do usuário está dentro do escopo do SYSRH usando Guardrails.
    """
    # VERIFICAÇÃO FORÇADA: Se esta mensagem não aparecer, o arquivo antigo está em cache.
    print("---[VERSÃO CORRIGIDA DO WORKFLOW EM EXECUÇÃO]---")

    user_input = state["solicitacao_original"]
    guard = gd.Guard.from_rail_string(rail_spec_topical)

    try:
        # --- FIX: Manual Prompt Construction to bypass Guardrails API incompatibility ---
        # We manually construct the prompt using the template from the RAIL spec
        # and then parse the output. This avoids the "You must provide messages" error.

        prompt_template = """
A pergunta do usuário é:
{user_input}

A pergunta está relacionada a algum dos seguintes tópicos?
- Sistema SYSRH
- Requisições de Mudança (RCM)
- Análise de evolutivas de software
- Planejamento de projetos de software
- Faturamento de projetos
- Manuais técnicos do sistema

Responda APENAS com o JSON.
"""
        formatted_prompt = prompt_template.format(user_input=user_input)

        # Call LLM directly
        llm_response = llm.invoke([HumanMessage(content=formatted_prompt)]).content

        # Clean up markdown code blocks if present (robustness)
        if "```json" in llm_response:
            llm_response = llm_response.split("```json")[1].split("```")[0].strip()
        elif "```" in llm_response:
            llm_response = llm_response.split("```")[1].split("```")[0].strip()

        # Parse using Guardrails
        validation_result = guard.parse(llm_response)

        if (
            validation_result.validation_passed
            and validation_result.validated_output["is_on_topic"]
        ):
            print("---[GUARDRAIL]: OK. A pergunta está no tópico.---")
            return {**state, "is_on_topic": True}

        # Se a validação passou mas o resultado foi 'false'
        print("---[GUARDRAIL]: FORA DO TÓPICO. Bloqueando fluxo.---")
        return {**state, "is_on_topic": False}

    except Exception as e:
        # Este bloco agora só deve ser atingido por erros REAIS, não pela incompatibilidade de API.
        print(f"---[GUARDRAIL]: OCORREU UM ERRO INESPERADO NA VALIDAÇÃO: {e}---")
        return {**state, "is_on_topic": False}


def run_analysis_workflow_node(state: GuardedState) -> GuardedState:
    """
    Executa o workflow de análise original.
    """
    print("---[WORKFLOW]: Tópico válido, iniciando análise completa...---")
    analista = AnalistaWorkflow(tools=get_tools())
    relatorio = analista.run(state["solicitacao_original"])
    return {**state, "final_report": relatorio}


def generate_off_topic_response_node(state: GuardedState) -> GuardedState:
    """
    Gera a resposta padrão para solicitações fora de tópico.
    """
    response = "Desculpe, como assistente do SYSRH, só posso analisar solicitações sobre evolutivas, RCMs, faturamento e manuais do sistema."
    fake_report = RelatorioAnalise(
        solicitacao_id=None,
        tipo_problema="Fora de Tópico",
        tipo_solicitacao="N/A",
        resumo_problema=state["solicitacao_original"],
        diagnostico=response,
        complexidade="N/A",
        solucao_sugerida="Nenhuma",
        nivel_esforco="N/A",
        esforco_resolucao_dias="N/A",
        detalhes_evolutiva=None,
    )
    return {**state, "final_report": fake_report}


# --- Lógica Condicional ---


def should_run_analysis(state: GuardedState) -> str:
    """Decide se o fluxo deve continuar para a análise ou parar."""
    if state["is_on_topic"]:
        return "run_analysis"
    return "generate_off_topic_response"


# --- Construção do Grafo ---

workflow = StateGraph(GuardedState)

workflow.add_node("guardrail_topical", check_topicality_node)
workflow.add_node("run_analysis_workflow", run_analysis_workflow_node)
workflow.add_node("generate_off_topic_response", generate_off_topic_response_node)

workflow.set_entry_point("guardrail_topical")

workflow.add_conditional_edges(
    "guardrail_topical",
    should_run_analysis,
    {
        "run_analysis": "run_analysis_workflow",
        "generate_off_topic_response": "generate_off_topic_response",
    },
)
workflow.add_edge("run_analysis_workflow", "__end__")
workflow.add_edge("generate_off_topic_response", "__end__")

guarded_app = workflow.compile()

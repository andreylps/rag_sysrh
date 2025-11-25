import logging
import sys
from pathlib import Path
from unittest.mock import MagicMock

# Add src to path
SRC_PATH = Path(__file__).resolve().parent / "src"
if str(SRC_PATH) not in sys.path:
    sys.path.append(str(SRC_PATH))

from dotenv import load_dotenv
from langchain_core.tools import Tool

from rag_sysrh.analista_workflow import AnalistaWorkflow

# Configure logging
logging.basicConfig(level=logging.INFO)
load_dotenv()


def verify_analista_prompts():
    print("--- Verifying AnalistaWorkflow Prompts & SISP Rules ---")

    # 1. Mock Tools
    # We need to mock the tools so we don't depend on the actual RAG/Neo4j for this prompt test
    factual_tool = MagicMock(spec=Tool)
    factual_tool.name = "Factual_Question_Answering"
    factual_tool.invoke.return_value = "Nenhuma solicitação similar encontrada."

    semantic_tool = MagicMock(spec=Tool)
    semantic_tool.name = "Semantic_Question_Answering"
    semantic_tool.invoke.return_value = "Procedimento padrão para criação de relatórios: O usuário deve especificar os campos e filtros."

    tools = [factual_tool, semantic_tool]

    # 2. Instantiate Workflow
    try:
        workflow = AnalistaWorkflow(tools=tools)
    except Exception as e:
        print(f"❌ Error instantiating AnalistaWorkflow: {e}")
        return

    # 3. Define Test Input (Improvement Request)
    # This input should trigger the "Melhoria" path and SISP calculation
    test_input = "Gostaria de incluir um novo campo 'Data de Nascimento' na tela de Cadastro de Usuários e um relatório que liste usuários por idade."

    print(f"\nInput: {test_input}")

    # 4. Run Workflow
    try:
        result = workflow.run(test_input)
    except Exception as e:
        print(f"❌ Error running workflow: {e}")
        import traceback

        traceback.print_exc()
        return

    # 5. Validate Output
    if not result:
        print("❌ Error: No result returned.")
        return

    print("\n--- Analysis Result ---")
    print(f"Tipo Problema: {result.tipo_problema}")
    print(f"Tipo Solicitação: {result.tipo_solicitacao}")
    print(f"Complexidade: {result.complexidade}")
    print(f"Nível Esforço: {result.nivel_esforco}")

    if result.detalhes_evolutiva:
        print("\n--- SISP Metrics ---")
        print(f"PF Estimado: {result.detalhes_evolutiva.estimativa_pontos_funcao}")
        print(f"Prazo (Dias Úteis): {result.detalhes_evolutiva.prazo_dias_uteis}")
        print(f"Data Entrega: {result.detalhes_evolutiva.data_prevista_entrega}")

        # Validation Logic
        pf = result.detalhes_evolutiva.estimativa_pontos_funcao
        days = result.detalhes_evolutiva.prazo_dias_uteis

        # Basic sanity check based on SISP rules injected
        # New field (ALI/EE) + Report (SE) -> likely > 0 PF
        if pf > 0:
            print("✅ SISP Check: PF > 0 (Calculation occurred)")
        else:
            print("❌ SISP Check: PF is 0 (Calculation failed)")

        # Check consistency with Tabela 9 (roughly)
        # Up to 10 PF -> 9 or 15 days
        if pf <= 10 and days in [9, 15]:
            print("✅ SISP Check: Deadline consistent with Table 9 for <= 10 PF")
        elif pf > 10:
            print(
                f"ℹ️ SISP Check: PF {pf} > 10, deadline {days} days. Verify manually against table."
            )
        else:
            print(
                f"⚠️ SISP Check: Deadline {days} days for {pf} PF might be inconsistent with Table 9 (expected 9 or 15)."
            )

    else:
        print("⚠️ No evolutionary details returned. Was it classified as 'Melhoria'?")

    if result.tipo_problema in ["Solicitação de Melhoria", "Melhoria"]:
        print("✅ Classification Check: Correctly classified as Improvement.")
    else:
        print(
            f"❌ Classification Check: Classified as {result.tipo_problema} (Expected Improvement)."
        )


if __name__ == "__main__":
    verify_analista_prompts()

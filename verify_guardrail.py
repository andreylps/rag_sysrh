import sys
from pathlib import Path

# Add src to path
SRC_PATH = Path(__file__).resolve().parent.parent / "src"
if str(SRC_PATH) not in sys.path:
    sys.path.append(str(SRC_PATH))


def test_guardrail():
    print("--- Testing Guardrail Fix (Manual Flow) ---")

    import os

    import guardrails as gd
    from dotenv import load_dotenv
    from langchain_core.messages import HumanMessage
    from langchain_openai import ChatOpenAI

    # Load environment variables
    project_root = Path(__file__).resolve().parent
    load_dotenv(project_root / ".env")

    from rag_sysrh.guardrails.rail_specs import rail_spec_topical

    llm = ChatOpenAI(model=os.getenv("OPENAI_MODEL", "gpt-4o"), temperature=0)
    guard = gd.Guard.from_rail_string(rail_spec_topical)

    # Manual prompt construction based on rail_spec_topical
    # We are extracting the prompt template manually for now to verify the flow
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

    # Test case 1: On-topic
    input_on_topic = "Como faço para solicitar férias?"
    print(f"\nInput: {input_on_topic}")
    try:
        formatted_prompt = prompt_template.format(user_input=input_on_topic)
        print(f"--- Prompt sent to LLM ---\n{formatted_prompt}\n----------------")

        llm_response = llm.invoke([HumanMessage(content=formatted_prompt)]).content
        print(f"--- LLM Response (Raw) ---\n{llm_response}\n----------------")

        # Clean up markdown code blocks if present
        if "```json" in llm_response:
            llm_response = llm_response.split("```json")[1].split("```")[0].strip()
        elif "```" in llm_response:
            llm_response = llm_response.split("```")[1].split("```")[0].strip()

        print(f"--- LLM Response (Cleaned) ---\n{llm_response}\n----------------")

        # Parse using Guardrails
        validation_result = guard.parse(llm_response)
        print(f"Validation Passed: {validation_result.validation_passed}")
        print(f"Validated Output: {validation_result.validated_output}")

        if (
            validation_result.validated_output
            and validation_result.validated_output.get("is_on_topic")
        ):
            print("SUCCESS: Correctly identified as on-topic.")
        else:
            print("FAILURE: Incorrectly identified as off-topic.")

    except Exception as e:
        print(f"ERROR in Test Case 1: {e}")
        import traceback

        traceback.print_exc()

    # Test case 2: Off-topic
    input_off_topic = "Qual a capital da Austrália?"
    print(f"\nInput: {input_off_topic}")
    try:
        formatted_prompt = prompt_template.format(user_input=input_off_topic)
        llm_response = llm.invoke([HumanMessage(content=formatted_prompt)]).content

        # Clean up markdown code blocks if present
        if "```json" in llm_response:
            llm_response = llm_response.split("```json")[1].split("```")[0].strip()
        elif "```" in llm_response:
            llm_response = llm_response.split("```")[1].split("```")[0].strip()

        print(f"--- LLM Response (Cleaned) ---\n{llm_response}\n----------------")

        validation_result = guard.parse(llm_response)
        print(f"Validation Passed: {validation_result.validation_passed}")
        print(f"Validated Output: {validation_result.validated_output}")

        if (
            validation_result.validated_output
            and not validation_result.validated_output.get("is_on_topic")
        ):
            print("SUCCESS: Correctly identified as off-topic.")
        else:
            print("FAILURE: Incorrectly identified as on-topic.")
    except Exception as e:
        print(f"ERROR in Test Case 2: {e}")
        import traceback

        traceback.print_exc()


if __name__ == "__main__":
    test_guardrail()

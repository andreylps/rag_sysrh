import os
import sys
import traceback
from pathlib import Path

from dotenv import load_dotenv
from langchain_core.messages import HumanMessage
from langchain_openai import ChatOpenAI
from pydantic import BaseModel, ValidationError

# Add src to path
SRC_PATH = Path(__file__).resolve().parent / "src"
if str(SRC_PATH) not in sys.path:
    sys.path.append(str(SRC_PATH))


class TopicValidation(BaseModel):
    is_on_topic: bool


def test_guardrail():
    print("--- Testing Guardrail Replacement (Pydantic) ---")

    # Load environment variables
    project_root = Path(__file__).resolve().parent
    load_dotenv(project_root / ".env")

    llm = ChatOpenAI(model=os.getenv("OPENAI_MODEL", "gpt-4o"), temperature=0)

    # Prompt Template
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
- Solicitações de Tecnologia da Informação (TI)
- Desenvolvimento e Manutenção de Sistemas
- Melhorias e Correções de Software
- Documentação de Requisitos

Responda APENAS com um JSON válido no seguinte formato:
{{
    "is_on_topic": true/false
}}
"""

    test_cases = [
        {"input": "Como faço para solicitar férias?", "expected_on_topic": True},
        {"input": "Qual a capital da Austrália?", "expected_on_topic": False},
        {
            "input": "Quero cadastrar uma nova RCM para o módulo de pagamentos.",
            "expected_on_topic": True,
        },
    ]

    for i, case in enumerate(test_cases):
        user_input = case["input"]
        expected = case["expected_on_topic"]
        print(f"\n[Test Case {i + 1}] Input: {user_input}")

        try:
            formatted_prompt = prompt_template.format(user_input=user_input)

            # 1. Invoke LLM
            llm_response = llm.invoke([HumanMessage(content=formatted_prompt)]).content

            # 2. Clean Response (Robustness)
            if "```json" in llm_response:
                llm_response = llm_response.split("```json")[1].split("```")[0].strip()
            elif "```" in llm_response:
                llm_response = llm_response.split("```")[1].split("```")[0].strip()

            # 3. Parse with Pydantic
            validation_result = TopicValidation.model_validate_json(llm_response)
            is_on_topic = validation_result.is_on_topic

            print(f"  LLM Response: {llm_response}")
            print(f"  Validated is_on_topic: {is_on_topic}")

            if is_on_topic == expected:
                print(f"  ✅ SUCCESS: Result matches expectation ({expected}).")
            else:
                print(f"  ❌ FAILURE: Result {is_on_topic} != Expectation {expected}.")

        except ValidationError as e:
            print(f"  ❌ VALIDATION ERROR: {e}")
        except Exception as e:
            print(f"  ❌ ERROR: {e}")
            traceback.print_exc()


if __name__ == "__main__":
    test_guardrail()

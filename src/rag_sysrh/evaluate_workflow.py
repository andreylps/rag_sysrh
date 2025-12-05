from pathlib import Path

from dotenv import load_dotenv  # type: ignore
from langsmith import evaluate  # type: ignore
from langsmith.schemas import Example, Run  # type: ignore

# Importação do seu workflow e ferramentas
from rag_sysrh.analista_workflow import AnalistaWorkflow
from rag_sysrh.main import get_tools


def evaluate_analista_custom():
    # 1. Setup de Ambiente
    project_root = Path(__file__).resolve().parent.parent.parent
    dotenv_path = project_root / ".env"
    load_dotenv(dotenv_path=dotenv_path)

    dataset_name = "AnalistaWorkflow - Avaliação Qualidade v1"

    print("Inicializando agente...")
    analista_agent = AnalistaWorkflow(tools=get_tools())

    # 2. Target Wrapper (O Agente)
    def target(inputs: dict):
        response = analista_agent.run(inputs["solicitacao"])

        # Tratamento robusto para converter o objeto Pydantic em dict
        response_dict = {}
        if hasattr(response, "model_dump"):  # Pydantic V2
            response_dict = response.model_dump()
        elif hasattr(response, "dict"):  # Pydantic V1
            response_dict = response.dict()
        elif isinstance(response, dict):
            response_dict = response
        else:
            return str(response)

        texto_final = (
            response_dict.get("resposta_final")
            or response_dict.get("relatorio")
            or str(response_dict)
        )
        return texto_final

    # 3. Avaliador Personalizado (COM EMOJIS)
    def avaliador_tamanho(run: Run, example: Example):
        """
        Verifica o tamanho e adiciona emojis no comentário.
        """
        resposta = run.outputs.get("output", "")
        tamanho = len(str(resposta))

        # Critério: Tamanho > 50 caracteres
        if tamanho > 50:
            score = 1
            # Emoji de Sucesso
            comment = f"✅ APROVADO: Relatório robusto ({tamanho} caracteres)."
        else:
            score = 0
            # Emoji de Falha
            comment = f"❌ REPROVADO: Resposta muito curta ({tamanho} caracteres)."

        return {"key": "check_tamanho", "score": score, "comment": comment}

    print(f"--- INICIANDO AVALIAÇÃO NO DATASET: {dataset_name} ---")

    # 4. Executar a Avaliação
    results = evaluate(
        target,
        data=dataset_name,
        evaluators=[avaliador_tamanho],
        experiment_prefix="teste-custom-eval",
        max_concurrency=1,
    )

    print("\n" + "=" * 30)
    print("RELATÓRIO FINAL")
    print("=" * 30)

    # 5. Exibir Resultados no Terminal
    try:
        df = results.to_pandas()
        coluna_feedback = "feedback.check_tamanho"

        if not df.empty and coluna_feedback in df.columns:
            passaram = df[df[coluna_feedback] == 1].shape[0]
            total = df.shape[0]

            print(f"📊 RESULTADO: {passaram}/{total} aprovações.")

            # Tenta mostrar os comentários com emojis no terminal também
            if "feedback.check_tamanho.comment" in df.columns:
                print("\n--- Detalhes ---")
                # Mostra apenas o input e o comentário do avaliador
                print(
                    df[["input.solicitacao", "feedback.check_tamanho.comment"]].head()
                )
            else:
                print(df[["input.solicitacao", coluna_feedback]].head())

        else:
            print(
                "⚠️ Resultados gerados, mas a coluna de feedback não foi encontrada no DataFrame local."
            )

    except Exception as e:
        print(
            f"Nota: Dados enviados ao LangSmith, mas erro ao imprimir no terminal: {e}"
        )

    print("\n➡️ Acesse o Dashboard: https://smith.langchain.com")


if __name__ == "__main__":
    evaluate_analista_custom()

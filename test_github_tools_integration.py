import asyncio

from dotenv import load_dotenv

from src.agents.github_tools import github_apply_labels, github_post_comment
from src.services.github_service import create_issue

# Carrega variáveis de ambiente
load_dotenv()


async def run_tests():
    print("=== Iniciando Teste de Integração das Tools do GitHub ===")

    # 1. Criar uma Issue de Teste
    print("\n1. Criando uma Issue de Teste...")
    try:
        issue_number = await create_issue(
            title="[TESTE] Integração de Tools do Agente",
            body="Esta é uma issue automática para testar as ferramentas do Agente de Triagem.",
        )
        print(f"✅ Issue criada com sucesso: #{issue_number}")
    except Exception as e:
        print(f"❌ Falha ao criar issue: {e}")
        return

    # 2. Testar Tool de Comentário
    print(f"\n2. Testando github_post_comment na issue #{issue_number}...")
    try:
        comment_body = "🤖 **Teste de Tool**: Comentário gerado automaticamente pelo `github_post_comment`."
        result = await github_post_comment.ainvoke(
            {"issue_number": issue_number, "comment_body": comment_body}
        )
        print(f"Resultado: {result}")
        if "Successfully posted" in result:
            print("✅ Sucesso")
        else:
            print("❌ Falha")
    except Exception as e:
        print(f"❌ Falha: {e}")

    # 3. Testar Tool de Labels
    print(f"\n3. Testando github_apply_labels na issue #{issue_number}...")
    try:
        # Adiciona uma label de teste
        result = await github_apply_labels.ainvoke(
            {
                "issue_number": issue_number,
                "labels_to_add": ["teste-tool-ia"],
                "labels_to_remove": [],
            }
        )
        print(f"Resultado: {result}")
        if "Successfully updated" in result:
            print("✅ Sucesso")
        else:
            print("❌ Falha")
    except Exception as e:
        print(f"❌ Falha: {e}")

    print("\n=== Teste Concluído ===")
    print(
        f"Por favor, verifique a issue #{issue_number} no GitHub para confirmar as alterações."
    )


if __name__ == "__main__":
    asyncio.run(run_tests())

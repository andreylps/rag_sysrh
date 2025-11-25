import asyncio
import os
import sys

# Add src to path
sys.path.append(os.path.join(os.path.dirname(__file__), "src"))

from services.github_service import create_issue, post_comment


async def main():
    print("--- Iniciando Teste do GitHub Service ---")

    title = "Teste Automatizado de Integração"
    body = "Esta é uma issue de teste criada via script Python para validar a integração com a API do GitHub."

    print(f"Criando issue: '{title}'...")
    try:
        issue_number = await create_issue(title, body)
        print(f"Sucesso! Issue criada: #{issue_number}")

        comment_body = "Olá do Python! 🐍\nEste comentário confirma que a integração de comentários está funcionando."
        print(f"Postando comentário na issue #{issue_number}...")
        await post_comment(issue_number, comment_body)
        print("Sucesso! Comentário postado.")

    except Exception as e:
        print(f"ERRO: {e}")


if __name__ == "__main__":
    asyncio.run(main())

import asyncio
import os
import sys

from dotenv import load_dotenv

# Add src to sys.path
sys.path.insert(0, os.getcwd())

from src.services.github_service import get_issue_details

load_dotenv()


async def test_connection():
    print("🔌 Testando conexão com GitHub REAL...")

    repo_name = os.getenv("GITHUB_REPO_NAME")
    print(f"📂 Repositório Alvo: {repo_name}")

    # Tenta buscar a issue #1 (geralmente existe em repositórios antigos, ou use uma que você sabe que existe)
    # Se não existir, vai dar 404, mas isso prova que conectou!
    target_issue = 1

    try:
        print(f"🔍 Buscando detalhes da Issue #{target_issue}...")
        details = await get_issue_details(target_issue)
        print("✅ SUCESSO! Conectado ao GitHub.")
        print(f"   Título da Issue: {details['title']}")
        print(f"   URL: {details['html_url']}")
    except Exception as e:
        print(
            "❌ Erro ao buscar issue (pode ser que ela não exista, mas a conexão falhou se for erro de credencial):"
        )
        print(f"   Erro: {e}")


if __name__ == "__main__":
    asyncio.run(test_connection())

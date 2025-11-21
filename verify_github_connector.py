import os
import sys
from pathlib import Path

from dotenv import load_dotenv

# Adiciona o diretório 'src' ao sys.path
SRC_PATH = Path(__file__).resolve().parent / "src"
if str(SRC_PATH) not in sys.path:
    sys.path.append(str(SRC_PATH))

from rag_sysrh.github_connector import GitHubConnector


def verify_github_connection():
    print("--- Verificando Conexão com GitHub ---")

    # Carrega variáveis de ambiente
    load_dotenv()

    token = os.getenv("GITHUB_TOKEN")
    repo_name = os.getenv("GITHUB_REPO_NAME")

    if not token:
        print("❌ GITHUB_TOKEN não encontrado no .env")
        print("Por favor, adicione GITHUB_TOKEN=seu_token_aqui no arquivo .env")
        return

    if not repo_name:
        print("⚠️ GITHUB_REPO_NAME não encontrado no .env")
        print(
            "Tentando usar um repositório padrão ou falhará se não definido na classe."
        )
        # Você pode definir um repo de teste aqui se quiser
        # repo_name = "usuario/repo-teste"

    print(f"Token detectado: {'*' * 5}{token[-4:] if token else 'Nenhum'}")
    print(f"Repositório alvo: {repo_name}")

    connector = GitHubConnector(token=token, repo_name=repo_name)

    try:
        print("\n1. Testando listagem de issues...")
        issues = connector.list_issues(state="open")
        print(f"✅ Sucesso! Encontradas {len(issues)} issues abertas.")
        for issue in issues[:3]:  # Mostra as 3 primeiras
            print(f"   - #{issue['number']}: {issue['title']} ({issue['html_url']})")

    except Exception as e:
        print(f"❌ Falha ao listar issues: {e}")
        return

    # Opcional: Teste de criação (Cuidado para não criar lixo em repos reais de produção sem querer)
    # Descomente abaixo para testar criação se estiver usando um repo de teste
    """
    try:
        print("\n2. Testando criação de issue de teste...")
        new_issue = connector.create_issue(
            title="[TESTE] Verificação Automática do Conector",
            body="Esta é uma issue de teste criada pelo script de verificação.",
            labels=["teste", "bot"]
        )
        if new_issue:
            print(f"✅ Issue criada com sucesso: {new_issue['html_url']}")
        else:
            print("❌ Falha ao criar issue.")
    except Exception as e:
        print(f"❌ Erro na criação: {e}")
    """


if __name__ == "__main__":
    verify_github_connection()

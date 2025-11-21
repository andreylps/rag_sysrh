import sys
from pathlib import Path

from dotenv import load_dotenv

# Adiciona o diretório 'src' ao sys.path
SRC_PATH = Path(__file__).resolve().parent / "src"
if str(SRC_PATH) not in sys.path:
    sys.path.append(str(SRC_PATH))

from rag_sysrh.github_connector import GitHubConnector


def verify_integration():
    print("--- Verificando Integração Completa GitHub ---")
    load_dotenv()

    # Dados simulados de uma RCM (como viriam do Agente de Planejamento)
    rcm_data = {
        "titulo_rcm": "Teste de Integração Automática",
        "objetivo_negocio": "Validar se o conector cria issues corretamente com o corpo formatado.",
        "descricao_tecnica_detalhada": "Esta é uma **RCM de teste** gerada pelo script de verificação.\nDeve conter formatação Markdown.",
        "plano_de_tarefas_sugerido": [
            "Verificar título",
            "Verificar corpo",
            "Verificar labels",
        ],
        "criterios_de_aceite": [
            "Issue criada no GitHub",
            "Link retornado corretamente",
        ],
        "riscos_mapeados": ["Token inválido", "Repo não existe"],
        "estimativa_pontos_funcao": 5,
        "prazo_dias_uteis": 2,
        "tipo_solicitacao": "Evolutiva",
    }

    try:
        connector = GitHubConnector()
        print(f"Conectado ao repo: {connector.repo_name}")

        print("Criando issue...")
        url = connector.create_issue(rcm_data)

        if url:
            print(f"✅ SUCESSO! Issue criada: {url}")
        else:
            print("❌ FALHA: URL não retornada.")

    except Exception as e:
        print(f"❌ ERRO: {e}")


if __name__ == "__main__":
    verify_integration()

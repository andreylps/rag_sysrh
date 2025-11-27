import os

from dotenv import load_dotenv

from src.agents.tools import (
    list_rhgov_files_tool,
    read_rhgov_file_tool,
    write_rhgov_file_tool,
)

# Carrega variáveis de ambiente
load_dotenv()


def run_tests():
    print("=== Iniciando Testes das Ferramentas de Sistema de Arquivos ===")

    root_path = os.getenv("RHGOV_PROJECT_ROOT")
    print(f"RHGOV_PROJECT_ROOT: {root_path}")

    if not root_path:
        print("❌ ERRO: RHGOV_PROJECT_ROOT não definido.")
        return

    # 1. Teste de Listagem
    print("\n--- Teste 1: Listar Arquivos (Raiz) ---")
    try:
        files = list_rhgov_files_tool.invoke({"relative_path": "."})
        print(f"Resultado:\n{files[:200]}...")  # Mostra apenas o início
        if "Diretório vazio" not in files and "Erro" not in files:
            print("✅ Sucesso")
        else:
            print("⚠️ Verifique o resultado.")
    except Exception as e:
        print(f"❌ Falha: {e}")

    # 2. Teste de Escrita
    print("\n--- Teste 2: Escrever Arquivo de Teste ---")
    test_file = "test_tool_fs.txt"
    content = "Este é um arquivo de teste criado pelo Agente."
    try:
        result = write_rhgov_file_tool.invoke(
            {"relative_path": test_file, "content": content}
        )
        print(f"Resultado: {result}")
        if "sucesso" in result:
            print("✅ Sucesso")
        else:
            print("❌ Falha")
    except Exception as e:
        print(f"❌ Falha: {e}")

    # 3. Teste de Leitura
    print("\n--- Teste 3: Ler Arquivo de Teste ---")
    try:
        read_content = read_rhgov_file_tool.invoke({"relative_path": test_file})
        print(f"Conteúdo Lido: {read_content}")
        if read_content == content:
            print("✅ Sucesso (Conteúdo corresponde)")
        else:
            print("❌ Falha (Conteúdo diverge)")
    except Exception as e:
        print(f"❌ Falha: {e}")

    # 4. Teste de Segurança (Path Traversal)
    print("\n--- Teste 4: Segurança (Path Traversal) ---")
    try:
        # Tenta acessar o .env do projeto RAG_SYSRH (que está fora do rh-gov-simulador)
        # Assumindo que rh-gov-simulador e RAG_SYSRH são irmãos
        result = read_rhgov_file_tool.invoke({"relative_path": "../RAG_SYSRH/.env"})
        print(f"Resultado (Esperado Erro): {result}")
        if "Acesso negado" in result or "Erro" in result:
            print("✅ Sucesso (Acesso bloqueado corretamente)")
        else:
            print("❌ FALHA CRÍTICA: Acesso não foi bloqueado!")
    except Exception as e:
        print(f"✅ Sucesso (Exceção capturada): {e}")


if __name__ == "__main__":
    run_tests()

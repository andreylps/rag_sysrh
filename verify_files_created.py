import os
import sys

from dotenv import load_dotenv

load_dotenv()

# Add src to sys.path
sys.path.insert(0, os.getcwd())

from src.services.file_system_service import read_file_content


def verify():
    print("🔍 Verificando arquivos gerados pelo Agente Dev...")

    # Arquivos esperados
    expected_files = [
        "app/models/departamento.py",
        "app/api/v1/endpoints/departamentos.py",
    ]

    found_all = True
    for file_path in expected_files:
        try:
            content = read_file_content(file_path)
            if content:
                print(f"✅ Arquivo encontrado: {file_path}")
                print(f"   Tamanho: {len(content)} bytes")
            else:
                print(f"❌ Arquivo vazio: {file_path}")
                found_all = False
        except Exception as e:
            print(f"❌ Arquivo não encontrado ou erro ao ler: {file_path}")
            print(f"   Erro: {e}")
            found_all = False

    if found_all:
        print("\n🎉 SUCESSO: Todos os arquivos esperados foram criados!")
        sys.exit(0)
    else:
        print(
            "\n⚠️ AVISO: Alguns arquivos ainda não foram criados. O agente pode ainda estar trabalhando."
        )
        sys.exit(1)


if __name__ == "__main__":
    verify()

from dotenv import load_dotenv

from src.agents.tools import search_project_codebase_and_docs_tool

# Carrega variáveis de ambiente
load_dotenv()


def run_tests():
    print("=== Iniciando Teste da Ferramenta de RAG (Memória) ===")

    # Query de teste: Algo que deve existir na base se os manuais foram ingeridos
    query = "Como criar um novo modelo SQLModel?"
    print(f"\n🔎 Buscando por: '{query}'...")

    try:
        result = search_project_codebase_and_docs_tool.invoke({"query": query})

        print("\n📄 Resultado da Busca:")
        print("=" * 60)
        print(result[:1000] + "..." if len(result) > 1000 else result)
        print("=" * 60)

        if "Nenhum documento" in result:
            print(
                "⚠️ Aviso: Nenhum documento encontrado. Verifique se o Vector Store está populado."
            )
        elif "Erro" in result:
            print("❌ Falha: Ocorreu um erro na consulta.")
        else:
            print("✅ Sucesso: Documentos recuperados.")

    except Exception as e:
        print(f"❌ Falha Crítica: {e}")


if __name__ == "__main__":
    run_tests()

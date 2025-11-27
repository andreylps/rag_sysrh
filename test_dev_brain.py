import asyncio
import os

from dotenv import load_dotenv

from src.agents.dev_agent import run_dev_agent

# Carrega variáveis de ambiente
load_dotenv()


async def run_tests():
    print("=== Iniciando Teste do Cérebro do Agente Desenvolvedor ===")

    # Tarefa de teste: Criar um arquivo de constantes seguindo padrões
    task = (
        "Crie um novo arquivo no simulador chamado 'app/core/constants_test_agent.py'. "
        "Adicione uma constante MAX_FERIAS_DIAS = 30 e uma constante EMPRESA_NOME = 'GovSim'. "
        "Use o RAG para verificar se já existem padrões de constantes ou configurações no projeto antes de criar. "
        "Se encontrar algo relevante, mencione no seu raciocínio."
    )

    print(f"\n🧠 Tarefa Enviada: {task}\n")
    print("⏳ Agente pensando e executando... (Isso pode levar alguns segundos)\n")

    try:
        result = await run_dev_agent(task)

        print("\n🤖 Resposta Final do Agente:")
        print("=" * 60)
        print(result)
        print("=" * 60)

        # Verificação manual do arquivo criado (opcional, mas bom para o teste)
        root_path = os.getenv("RHGOV_PROJECT_ROOT")
        if root_path:
            file_path = os.path.join(root_path, "app/core/constants_test_agent.py")
            if os.path.exists(file_path):
                print(f"\n✅ SUCESSO: O arquivo '{file_path}' foi criado fisicamente!")
                with open(file_path, "r", encoding="utf-8") as f:
                    print(f"📄 Conteúdo do Arquivo:\n{f.read()}")
            else:
                print(f"\n❌ FALHA: O arquivo '{file_path}' NÃO foi encontrado.")

    except Exception as e:
        print(f"❌ Falha Crítica no Teste: {e}")


if __name__ == "__main__":
    asyncio.run(run_tests())

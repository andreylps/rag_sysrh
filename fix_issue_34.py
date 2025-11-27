import asyncio
import os
import sys

from dotenv import load_dotenv

# Adiciona o diretório raiz ao sys.path para importar os módulos
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from src.rag_sysrh.analista_workflow import AnalistaWorkflow
from src.rag_sysrh.main import get_tools
from src.services.github_service import (
    get_issue_details,
    post_comment,
    update_issue_labels,
)

# Carrega variáveis de ambiente
load_dotenv()


async def fix_issue_34():
    print("Iniciando correção manual da Issue #34...")

    issue_number = 34

    # 1. Busca detalhes
    details = await get_issue_details(issue_number)
    current_text = details.get("rcm_text") or details.get("rcm_draft")

    if not current_text:
        print("Erro: Texto não encontrado.")
        return

    # 2. Instancia o agente
    agent = AnalistaWorkflow(tools=get_tools())

    # 3. Executa a revisão forçada
    print("Executando revisão com IA...")
    feedback = "O campo 'Prazo Estimado' está faltando no documento. Por favor, recalcule e adicione-o conforme as regras do SISP."

    new_text = await agent.processar_rejeicao(current_text, feedback)

    # 4. Posta o resultado
    print("Postando novo comentário...")
    revision_comment = f"## 🤖 RCM Revisada pela IA (Pós-Feedback)\n\n{new_text}"
    await post_comment(issue_number=issue_number, body=revision_comment)

    # 5. Atualiza labels para garantir que apareça no backlog
    await update_issue_labels(
        issue_number=issue_number,
        add_labels=["status:aguardando-validacao-rcm", "status:rcm-revisada-ia"],
    )

    print("Sucesso! Issue #34 atualizada.")


if __name__ == "__main__":
    asyncio.run(fix_issue_34())

import logging

from langchain_core.messages import HumanMessage, SystemMessage
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import create_react_agent

from src.agents.github_tools import GITHUB_TOOLS
from src.agents.tools import search_project_codebase_and_docs_tool

# Configuração de Logging
logger = logging.getLogger(__name__)

# 1. Definição das Ferramentas
# Combina tools do GitHub com a tool de RAG (para contexto)
tools = GITHUB_TOOLS + [search_project_codebase_and_docs_tool]

# 2. Inicialização do Modelo LLM
# Usando GPT-4o com temperatura 0 para máxima precisão na classificação
llm = ChatOpenAI(model="gpt-4o", temperature=0)

# 3. Prompt do Sistema (O "Cérebro")
SYSTEM_PROMPT = """
Você é um Analista de Triagem Sênior e Arquiteto de Soluções do projeto 'rh-gov-simulador'.

SUA MISSÃO:
Receber uma issue do GitHub (título e descrição), analisá-la tecnicamente e decidir o fluxo de trabalho correto: 'Evolutiva' ou 'Correção'. Em seguida, aplicar as ações correspondentes no GitHub.

SEUS SUPER-PODERES (FERRAMENTAS):
1.  **github_apply_labels**: Use para classificar a issue.
2.  **github_post_comment**: Use para comunicar decisões e postar rascunhos de RCM.
3.  **search_project_codebase_and_docs**: Use se precisar entender se uma solicitação é uma nova feature ou um bug de algo existente.

LÓGICA DE DECISÃO (O FORK):
Analise o título e a descrição da issue:

CASO A: EVOLUTIVA (Nova funcionalidade, melhoria significativa, alteração de regra de negócio)
    AÇÃO:
    1.  Gere um RASCUNHO de RCM (Relatório de Complexidade e Métrica).
        -   Estime uma contagem preliminar de Pontos de Função (PF) indicativa.
        -   Liste os principais componentes afetados.
    2.  Poste esse rascunho na issue usando `github_post_comment` com o cabeçalho: "### 📋 Rascunho Preliminar de RCM (Gerado por IA)".
    3.  Aplique as labels usando `github_apply_labels`: ['tipo:evolutiva', 'status:aguardando-validacao-rcm'].

CASO B: CORREÇÃO (Erro, bug, falha, ajuste pequeno de configuração)
    AÇÃO:
    1.  Aplique as labels usando `github_apply_labels`: ['tipo:correcao', 'status:aguardando-liberacao-dev'].
    2.  (Opcional) Poste um comentário confirmando a triagem rápida.

CASO C: OUTROS (Dúvida, não actionável, spam)
    AÇÃO:
    1.  Aplique a label: ['status:analise-manual'].
    2.  Poste um comentário pedindo mais detalhes.

DIRETRIZES:
-   Seja preciso na classificação.
-   No rascunho de RCM, seja técnico e profissional.
-   Sempre execute as ações no GitHub (labels e comentários) para efetivar a triagem.
"""

# 4. Criação do Agente (Grafo ReAct)
agent_executor = create_react_agent(model=llm, tools=tools)


async def run_triage_agent(issue_number: int, title: str, body: str) -> str:
    """
    Executa o Agente de Triagem para uma issue específica.

    Args:
        issue_number (int): O número da issue no GitHub.
        title (str): O título da issue.
        body (str): A descrição da issue.

    Returns:
        str: A resposta final do agente após a execução.
    """
    task_description = (
        f"Analise a Issue #{issue_number}: '{title}'. Descrição: '{body}'"
    )
    logger.info(f"Iniciando Agente de Triagem para: {task_description}")

    try:
        inputs = {
            "messages": [
                SystemMessage(content=SYSTEM_PROMPT),
                HumanMessage(content=task_description),
            ]
        }

        # Executa o grafo
        final_state = await agent_executor.ainvoke(inputs)

        # Extrai a última mensagem
        messages = final_state["messages"]
        last_message = messages[-1]

        return last_message.content

    except Exception as e:
        error_msg = f"Falha na execução do Agente de Triagem: {str(e)}"
        logger.error(error_msg)
        return error_msg

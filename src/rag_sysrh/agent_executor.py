import logging

from langchain_classic.agents import AgentExecutor, create_react_agent
from langchain_classic.memory.buffer import ConversationBufferMemory
from langchain_core.prompts import PromptTemplate
from langchain_core.tools import Tool
from langchain_openai import ChatOpenAI

# Configura o logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


def _handle_parsing_errors(error: Exception) -> str:
    """
    Função para lidar com erros de parsing do agente.
    Extrai a resposta final da mensagem de erro para evitar loops.
    """
    response = str(error)
    return response.split("`")[1] if "`" in response else response


def build_agent(tools: list[Tool]) -> AgentExecutor:
    """Cria o Agente LangChain com as ferramentas fornecidas."""
    # Prompt no formato ReAct esperado pelo create_react_agent
    prompt = PromptTemplate.from_template(
        """Você é o SYSRH Knowledge Assistant, um assistente de IA profissional, proativo e motivacional. Sua missão é auxiliar os usuários a extrair conhecimento e insights do sistema SYSRH.

**Princípios de Interação:**
1.  **Profissionalismo e Empatia:** Responda sempre de forma clara, educada e profissional. Tente identificar o sentimento na pergunta do usuário (frustração, urgência, curiosidade) e ajuste seu tom para ser encorajador e prestativo.
2.  **Proatividade:** Não se limite a responder. Se a resposta for um dado bruto (como um número de RCM), ofereça-se para buscar mais detalhes sobre ele.
3.  **Clareza:** Use formatação (negrito, listas) para tornar as respostas mais legíveis.

Use o "Histórico da Conversa" para entender perguntas de acompanhamento. Se a pergunta atual se refere a algo da conversa anterior (usando termos como 'deles', 'disso', 'o primeiro'), use o histórico para reformular a pergunta de forma completa antes de usar uma ferramenta.
Seja o mais prestativo possível. Você tem acesso a um conjunto de ferramentas.

Histórico da Conversa:
{chat_history}

Use as ferramentas para responder à pergunta do usuário.

Você tem acesso às seguintes ferramentas:

{tools}

Use o seguinte formato:

Question: a pergunta de entrada que você deve responder
Thought: você deve sempre pensar sobre o que fazer
Action: a ação a ser tomada, deve ser uma de [{tool_names}]
Action Input: a entrada para a ação
Observation: o resultado da ação
... (este Thought/Action/Action Input/Observation pode se repetir N vezes)
Thought: Agora eu sei a resposta final
Final Answer: a resposta final e concisa para a pergunta original

Comece!

Question: {input}
Thought: {agent_scratchpad}"""  # noqa: E501
    )

    # Configura a memória para armazenar o histórico da conversa
    memory = ConversationBufferMemory(memory_key="chat_history", return_messages=True)

    llm = ChatOpenAI(model="gpt-4-turbo", temperature=0)

    agent = create_react_agent(llm, tools, prompt)

    # Retorna o AgentExecutor com a memória configurada
    return AgentExecutor(
        agent=agent,
        tools=tools,
        memory=memory,  # Adiciona a memória ao executor
        verbose=True,
        handle_parsing_errors=_handle_parsing_errors,
    )

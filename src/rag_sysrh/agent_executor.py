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


def build_agent(tools: list[Tool]) -> AgentExecutor:
    """Cria o Agente LangChain com as ferramentas fornecidas."""
    # Prompt no formato ReAct esperado pelo create_react_agent
    prompt = PromptTemplate.from_template(
        """Você é um agente especialista em responder perguntas sobre um banco de dados Neo4j.
Seja o mais prestativo possível. Você tem acesso a um conjunto de ferramentas.

Use o "Histórico da Conversa" para entender perguntas de acompanhamento. Se a pergunta atual se refere a algo da conversa anterior (usando termos como 'deles', 'disso', 'o primeiro'), use o histórico para reformular a pergunta de forma completa antes de usar uma ferramenta.

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
Final Answer: a resposta final para a pergunta original

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
        handle_parsing_errors=True,
    )

import json
import logging
import os

from dotenv import load_dotenv
from langchain_community.vectorstores import Neo4jVector
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.runnables import RunnablePassthrough
from langchain_core.tools import Tool
from langchain_neo4j import Neo4jGraph
from langchain_openai import ChatOpenAI, OpenAIEmbeddings

# Configura o logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)

load_dotenv()

# --- CONFIGURAÇÃO GLOBAL (NÍVEL DO MÓDULO) ---

# Validação de chaves e conexão
if not os.getenv("OPENAI_API_KEY"):
    msg = "A variável de ambiente OPENAI_API_KEY não foi definida."
    raise ValueError(msg)

NEO4J_URI = os.getenv("NEO4J_URI")
NEO4J_USERNAME = os.getenv("NEO4J_USERNAME")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD")

# Configurações do modelo de linguagem
LLM_MODEL = "gpt-4-turbo"
LLM_TEMPERATURE = 0


def get_tools() -> list[Tool]:
    """
    Cria e retorna a lista de ferramentas (agentes especialistas) para o orquestrador.
    """
    try:
        graph = Neo4jGraph(
            url=NEO4J_URI, username=NEO4J_USERNAME, password=NEO4J_PASSWORD
        )
        graph.refresh_schema()
        logging.info("Conexão com Neo4j e schema atualizado com sucesso.")  # noqa: LOG015
    except Exception as e:
        logging.exception("Falha crítica ao conectar ao Neo4j: %s", e)  # noqa: LOG015, TRY401
        raise

    llm = ChatOpenAI(model=LLM_MODEL, temperature=LLM_TEMPERATURE)

    # --- FERRAMENTA 1: BUSCA SEMÂNTICA (VETORIAL) ---
    qa_prompt = ChatPromptTemplate.from_template(
        """Você é um assistente que responde perguntas com base em informações extraídas de um banco de dados em grafo.
    Sua tarefa é responder à "Pergunta" usando apenas os dados fornecidos na "Informação do Grafo".
    Se a informação não for suficiente, responda exatamente "Não sei a resposta".
    Se a pergunta pede uma lista, retorne os itens. Se pede um texto, retorne o texto. Seja direto.

    Informação do Grafo:
    {context}

    Pergunta: {input}
    Resposta Direta:"""  # noqa: E501
    )

    vector_index = Neo4jVector.from_existing_index(
        OpenAIEmbeddings(),
        url=NEO4J_URI,
        username=NEO4J_USERNAME,
        password=NEO4J_PASSWORD,
        index_name="manual-chunks",
        text_node_property="texto",
    )

    retriever = vector_index.as_retriever(search_kwargs={"k": 3})
    # Cadeia LCEL para busca semântica
    semantic_qa_chain = (
        {"context": retriever, "input": RunnablePassthrough()}
        | qa_prompt
        | llm
        | StrOutputParser()
    )

    def run_semantic_chain(question: str) -> str:
        """Executa a cadeia semântica e retorna apenas a resposta."""
        return semantic_qa_chain.invoke(question)

    semantic_tool = Tool(
        name="Semantic_Question_Answering",
        func=run_semantic_chain,
        description="""Útil para responder perguntas conceituais, de procedimento ou abertas sobre 'como fazer', 'quais são as regras', 'explique sobre'.
    Use esta ferramenta para questões que não buscam um ID, nome ou número específico, mas sim uma explicação.
    Exemplos de entrada: 'Como funciona o processo de férias?', 'Quais são as regras de negócio para consignação?'""",  # noqa: E501
    )

    # --- FERRAMENTA 2: BUSCA FATORIAL (CYPHER) ---
    cypher_qa_prompt = ChatPromptTemplate.from_template(
        """Você é um expert em Neo4j. Sua tarefa é gerar uma consulta Cypher a partir de uma pergunta do usuário, usando o schema do grafo.
Instruções importantes para a geração de Cypher:
1. Para perguntas sobre 'procedimentos', 'regras' ou 'como fazer', busque no nó `:Manual` usando `CONTAINS` na propriedade `texto`. Exemplo para 'férias': `MATCH (c:Chunk)-[:PARTE_DE]->(m:Manual) WHERE c.texto CONTAINS 'férias' RETURN c.texto`.
2. Quando uma pergunta pedir para listar ou identificar uma 'solicitação', sempre retorne a propriedade `Title` do nó `Solicitacao`, que contém o número do chamado (ex: '3225/2025'). Exemplo para 'alesc': `MATCH (s:Solicitacao)-[:ASSOCIADA_A]->(c:Cliente) WHERE toLower(c.nome) = 'alesc' RETURN s.Title`.
3. Para buscar por número de processo como '3225/2025', use `STARTS WITH` na propriedade `Title` do nó `Solicitacao`. Exemplo: `MATCH (r:RCM)-[:ORIGINADO_DE]->(s:Solicitacao) WHERE s.Title STARTS WITH '3225/2025' RETURN r.texto_completo`.
4. Para buscar por ID de solicitação (ex: 99797), filtre a propriedade `id` do nó `Solicitacao` com `toFloat()`. Exemplo: `MATCH (s:Solicitacao) WHERE toFloat(s.id) = 99797.0 RETURN s.descricao`.
5. Para buscar por status (ex: 'Aberta', 'RECUSADO'), use `toLower()` na propriedade `status` do nó `Solicitacao`. Exemplo: `MATCH (s:Solicitacao) WHERE toLower(s.status) = 'recusado' RETURN count(s)`.
6. Para buscar por código de manual (ex: 'UCS0083'), filtre a propriedade `codigo_ucs` no nó `:Manual`. Exemplo: `MATCH (m:Manual) WHERE m.codigo_ucs = 'UCS0083' RETURN m.texto_completo`.
7. Para buscar por 'Regra de Negócio' ou 'RN' (ex: 'RN001'), combine buscas com `AND`. Exemplo: `MATCH (m:Manual) WHERE m.texto_completo CONTAINS 'RN001' AND m.texto_completo CONTAINS 'Proposta de Consignação' RETURN m.texto_completo`.
8. Se a pergunta for sobre RCMs de um cliente, primeiro encontre as solicitações do cliente e depois as RCMs relacionadas. Exemplo: `MATCH (r:RCM)-[:ORIGINADO_DE]->(s:Solicitacao)-[:ASSOCIADA_A]->(c:Cliente) WHERE toLower(c.nome) = 'alesc' RETURN r.id`.

Schema:
{schema}

Pergunta: {input}
Consulta Cypher:"""  # noqa: E501
    )
    # Cadeia LCEL para geração de Cypher
    cypher_chain = (
        {"schema": lambda _: graph.get_schema, "input": RunnablePassthrough()}
        | cypher_qa_prompt
        | llm
        | StrOutputParser()
    )

    def run_qa_chain(question: str) -> str:
        try:
            generated_cypher = cypher_chain.invoke(question)
            logging.info(f"Cypher Gerado: {generated_cypher}")  # noqa: G004, LOG015
            result = graph.query(generated_cypher)
            return json.dumps(result)
        except Exception as e:
            logging.exception("Falha na execução da consulta Cypher: %s", e)  # noqa: LOG015, TRY401
            return "Desculpe, ocorreu um erro ao buscar a informação no banco de dados."

    factual_tool = Tool(
        name="Factual_Question_Answering",
        func=run_qa_chain,
        description="""Útil para responder perguntas factuais que buscam IDs, nomes, números, listas ou contagens.
    Use esta ferramenta para perguntas sobre solicitações, RCMs, clientes e seus relacionamentos.
    Exemplos de entrada: 'Qual o ID da solicitação 3225/2025?', 'Liste as 5 últimas solicitações do cliente Alesc', 'Quantas RCMs existem para o cliente UDESC?'""",  # noqa: E501
    )

    return [semantic_tool, factual_tool]

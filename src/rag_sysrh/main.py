import json
import logging
import os
import re

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


def get_tools() -> list[Tool]:  # noqa: C901, PLR0915
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
        {"context": retriever, "input": RunnablePassthrough()}  # type: ignore  # noqa: PGH003
        | qa_prompt
        | llm
        | StrOutputParser()
    )

    def run_semantic_chain(question: str) -> str:
        """Executa a cadeia semântica e retorna apenas a resposta."""
        try:
            return semantic_qa_chain.invoke(question)  # type: ignore  # noqa: PGH003
        except Exception as e:
            logging.exception("Falha na execução da cadeia semântica: %s", e)  # noqa: LOG015, TRY401
            return "Desculpe, ocorreu um erro ao buscar a informação nos manuais."

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
2. Quando uma pergunta pedir para listar ou identificar uma 'solicitação', sempre retorne a propriedade `title` do nó `Solicitacao`, que contém o número do chamado (ex: '3225/2025'). Exemplo para 'alesc': `MATCH (s:Solicitacao)-[:ASSOCIADA_A]->(c:Cliente) WHERE toLower(c.nome) = 'alesc' RETURN s.title`.
3. Se a pergunta usar um número de chamado, como '20511' ou '20511/2024', ele sempre se refere à propriedade `title`. Use o operador `STARTS WITH` para a busca. Para retornar a descrição completa, use a propriedade `texto_completo`. Exemplo para "descrição do chamado 20511": `MATCH (s:Solicitacao) WHERE s.title STARTS WITH '20511' RETURN s.title, s.status, s.texto_completo`.
4. A propriedade `id` é um identificador interno do sistema. Use-a para busca somente se a pergunta mencionar explicitamente "ID da solicitação". Exemplo para "ID da solicitação 80679": `MATCH (s:Solicitacao) WHERE toFloat(s.id) = 80679.0 RETURN s.description`.
5. Para buscar por status (ex: 'Aberta', 'RECUSADO'), use `toLower()` na propriedade `status` do nó `Solicitacao`. Exemplo: `MATCH (s:Solicitacao) WHERE toLower(s.status) = 'recusado' RETURN count(s)`.
6. Para buscar por código de manual (ex: 'UCS0083'), filtre a propriedade `codigo_ucs` no nó `:Manual`. Exemplo: `MATCH (m:Manual) WHERE m.codigo_ucs = 'UCS0083' RETURN m.texto_completo`.
7. Para buscar por 'Regra de Negócio' ou 'RN' (ex: 'RN001'), combine buscas com `AND`. Exemplo: `MATCH (m:Manual) WHERE m.texto_completo CONTAINS 'RN001' AND m.texto_completo CONTAINS 'Proposta de Consignação' RETURN m.texto_completo`.
8. Se a pergunta for sobre RCMs de um cliente, primeiro encontre as solicitações do cliente e depois as RCMs relacionadas. Exemplo: `MATCH (r:RCM)-[:ORIGINADO_DE]->(s:Solicitacao)-[:ASSOCIADA_A]->(c:Cliente) WHERE toLower(c.nome) = 'alesc' RETURN r.id`.
9. **IMPORTANTE para UNION**: Se você precisar combinar resultados de diferentes tipos de nós usando `UNION`, **SEMPRE** use aliases (`AS`) para garantir que os nomes das colunas de retorno sejam idênticos em todas as partes da consulta.
   Exemplo de `UNION` correto:
     `MATCH (s:Solicitacao) WHERE s.title CONTAINS 'relatório' RETURN s.title AS titulo, s.texto_completo AS descricao`
     `UNION`
     `MATCH (r:RCM) WHERE r.titulo CONTAINS 'relatório' RETURN r.titulo AS titulo, r.id AS descricao`

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
            generated_cypher_raw = cypher_chain.invoke(question)
            logging.info(f"Cypher Gerado: {generated_cypher_raw}")  # noqa: G004, LOG015

            # Usa regex para extrair de forma robusta a query de dentro do bloco de markdown  # noqa: E501
            match = re.search(r"```cypher\n(.*?)\n```", generated_cypher_raw, re.DOTALL)
            if match:
                generated_cypher = match.group(1).strip()
            else:
                # Se o LLM não retornar o bloco de markdown, usa a resposta como está
                generated_cypher = generated_cypher_raw.strip()

            result = graph.query(generated_cypher)
            if not result:
                return "Nenhum resultado encontrado para esta consulta."
            return json.dumps(result, ensure_ascii=False)
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

    # --- FERRAMENTA 3: AGENTE DE FATURAMENTO ---
    billing_cypher_prompt = ChatPromptTemplate.from_template(
        """Você é um expert em Neo4j e finanças. Sua tarefa é gerar uma consulta Cypher para calcular custos de solicitações.

Instruções:
1.  **Diferencie o tipo de solicitação:** O faturamento de chamados 'Evolutivo' ou 'Melhoria' é baseado em Pontos de Função (`s.effort`). O faturamento dos demais tipos ('Corretivo', 'Operacao', etc.) é baseado em horas (`s.horas_realizadas`).
2.  **Custo por Ponto de Função:** Para chamados evolutivos, multiplique `s.effort` pelo valor do nó `:Custo {tipo: 'ponto_funcao'}`.
3.  **Custo por Hora:** Para os demais chamados, multiplique `s.horas_realizadas` pelo valor do nó `:Custo {tipo: 'hora_desenvolvimento'}`.
4.  **Exemplo para 'custo do chamado evolutivo 123'**: `MATCH (s:Solicitacao) WHERE s.id = 123 MATCH (c:Custo {tipo:'ponto_funcao'}) RETURN s.effort * c.valor AS custo_total`.
5.  **Exemplo para 'custo do chamado corretivo 456'**: `MATCH (s:Solicitacao) WHERE s.id = 456 MATCH (c:Custo {tipo:'hora_desenvolvimento'}) RETURN s.horas_realizadas * c.valor AS custo_total`.
6.  Se a pergunta especificar um cliente, filtre as solicitações por esse cliente antes de somar os custos.
Schema:
{schema}

Pergunta: {input}
Consulta Cypher:"""  # noqa: E501
    )

    billing_cypher_chain = (
        {"schema": lambda _: graph.get_schema, "input": RunnablePassthrough()}
        | billing_cypher_prompt
        | llm
        | StrOutputParser()
    )

    def run_billing_chain(question: str) -> str:
        """Executa a cadeia de faturamento e retorna o resultado."""
        generated_cypher_raw = billing_cypher_chain.invoke(question)
        logging.info(f"Cypher de Faturamento Gerado: {generated_cypher_raw}")  # noqa: G004, LOG015
        try:
            # Usa regex para extrair de forma robusta a query de dentro do bloco de markdown  # noqa: E501
            match = re.search(r"```cypher\n(.*?)\n```", generated_cypher_raw, re.DOTALL)
            if match:
                generated_cypher = match.group(1).strip()
            else:
                generated_cypher = generated_cypher_raw.strip()

            result = graph.query(generated_cypher)
            if not result:
                return "Nenhum resultado encontrado para esta consulta."
            return json.dumps(result, ensure_ascii=False)
        except Exception as e:
            logging.exception("Falha na execução da consulta de faturamento: %s", e)  # noqa: LOG015, TRY401
            return "Erro ao calcular o faturamento."

    billing_tool = Tool(
        name="Billing_Calculator",
        func=run_billing_chain,
        description="""Útil para responder perguntas sobre custos, faturamento ou valor de solicitações e projetos.
    Use esta ferramenta para perguntas como 'Qual o custo do chamado X?', 'Qual o faturamento do cliente Y?'.""",  # noqa: E501
    )

    return [semantic_tool, factual_tool, billing_tool]

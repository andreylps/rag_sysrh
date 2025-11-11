import json
import logging
import os
from typing import cast

from dotenv import load_dotenv
from langchain_classic.chains import RetrievalQA
from langchain_community.vectorstores import Neo4jVector
from langchain_core.prompts import PromptTemplate
from langchain_core.tools import Tool
from langchain_neo4j import Neo4jGraph
from langchain_openai import ChatOpenAI, OpenAIEmbeddings

from rag_sysrh.agent_executor import build_agent

# Configura o logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


def main() -> None:
    """
    Função principal para executar o assistente de consulta SYSRH de forma interativa.
    """
    load_dotenv()

    if not os.getenv("OPENAI_API_KEY"):
        logging.error("A variável de ambiente OPENAI_API_KEY não foi definida.")
        return

    try:
        NEO4J_URI = os.getenv("NEO4J_URI")
        NEO4J_USER = os.getenv("NEO4J_USER")
        NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD")
        logging.info("Variáveis de ambiente do Neo4j carregadas.")

        # Cria a instância do grafo uma vez para ser usada em múltiplos locais
        graph = Neo4jGraph(url=NEO4J_URI, username=NEO4J_USER, password=NEO4J_PASSWORD)
        # Atualiza o schema para o LLM saber quais nós e relacionamentos existem
        graph.refresh_schema()
        logging.info("Schema do grafo Neo4j atualizado para o LLM.")

    except Exception as e:
        logging.exception("Falha ao conectar ao Neo4j: %s", e)
        return

    llm = ChatOpenAI(model="gpt-4", temperature=0)
    cypher_llm = ChatOpenAI(model="gpt-4", temperature=0)  # LLM dedicado para Cypher

    # --- PROMPT PARA RESUMIR O RESULTADO DA CONSULTA ---
    # Este prompt instrui o LLM a criar uma resposta concisa a partir dos dados do grafo.
    # Isso evita que textos enormes (manuais inteiros) sejam enviados, prevenindo erros de limite de token.
    qa_prompt = PromptTemplate.from_template(
        """Você é um assistente que responde perguntas com base em informações extraídas de um banco de dados em grafo.
Sua tarefa é responder à "Pergunta" usando apenas os dados fornecidos na "Informação do Grafo".
Se a informação não for suficiente, responda exatamente "Não sei a resposta".
Se a pergunta pede uma lista, retorne os itens. Se pede um texto, retorne o texto. Seja direto.

Informação do Grafo:
{context}

Pergunta: {question}
Resposta Direta:"""
    )

    # --- FERRAMENTA 1: BUSCA SEMÂNTICA (VETORIAL) ---
    # Esta ferramenta é para perguntas abertas, conceituais ou de procedimento.

    # Configura a conexão com o índice de vetores do Neo4j
    vector_index = Neo4jVector.from_existing_index(
        OpenAIEmbeddings(),
        url=NEO4J_URI,
        username=NEO4J_USER,
        password=NEO4J_PASSWORD,
        index_name="manual-chunks",  # O nome do índice que criamos na ingestão
        text_node_property="texto",  # A propriedade do nó que contém o texto
    )

    # Cria a cadeia de RetrievalQA que usa o índice de vetores
    # Esta é a abordagem "clássica" e mais estável para este ambiente.
    semantic_qa_chain = RetrievalQA.from_chain_type(
        llm=llm,
        chain_type="stuff",  # "stuff" simplesmente junta os chunks encontrados
        retriever=vector_index.as_retriever(
            search_kwargs={"k": 3}
        ),  # Busca os 3 chunks mais relevantes
        chain_type_kwargs={"prompt": qa_prompt},  # Usa nosso prompt customizado
    )

    semantic_tool = Tool(
        name="Semantic_Question_Answering",
        func=semantic_qa_chain.run,
        description="""Útil para responder perguntas conceituais, de procedimento ou abertas sobre 'como fazer', 'quais são as regras', 'explique sobre'.
Use esta ferramenta para questões que não buscam um ID, nome ou número específico, mas sim uma explicação.
Exemplos de entrada: 'Como funciona o processo de férias?', 'Quais são as regras de negócio para consignação?'""",
    )

    # --- FERRAMENTA 2: BUSCA FATORIAL (CYPHER) ---
    # Esta ferramenta é para perguntas que buscam dados específicos e estruturados.

    # CADEIA SIMPLIFICADA: Gera Cypher e retorna o resultado bruto.
    # Isso é mais robusto do que usar a GraphCypherQAChain completa.
    cypher_generation_prompt = PromptTemplate.from_template(
        """Você é um expert em Neo4j. Sua tarefa é gerar uma consulta Cypher a partir de uma pergunta do usuário, usando o schema do grafo.
Schema:
{schema}

Pergunta: {question}
Consulta Cypher:"""
    )
    cypher_chain = cypher_generation_prompt | cypher_llm

    def run_qa_chain(question: str) -> str:
        try:
            # --- PROMPT ENGINEERING APLICADO AQUI ---
            # Adicionamos instruções detalhadas para guiar o LLM na geração de Cypher.
            # Esta parte continua crucial para a qualidade da consulta gerada.
            enhanced_question = f"""Use o schema do grafo e as instruções abaixo para gerar uma consulta Cypher.
            Instruções importantes para a geração de Cypher:
            1. Para perguntas sobre 'procedimentos', 'regras' ou 'como fazer', busque no nó `:Manual` usando `CONTAINS` na propriedade `texto`. Exemplo para 'férias': `MATCH (c:Chunk)-[:PARTE_DE]->(m:Manual) WHERE c.texto CONTAINS 'férias' RETURN c.texto`.
            2. Quando uma pergunta pedir para listar ou identificar uma 'solicitação', sempre retorne a propriedade `Title` do nó `Solicitacao`, que contém o número do chamado (ex: '3225/2025'). Exemplo para 'alesc': `MATCH (s:Solicitacao)-[:ASSOCIADA_A]->(c:Cliente) WHERE toLower(c.nome) = 'alesc' RETURN s.Title`.
            3. Para buscar por número de processo como '3225/2025', use `STARTS WITH` na propriedade `Title` do nó `Solicitacao`. Exemplo: `MATCH (r:RCM)-[:ORIGINADO_DE]->(s:Solicitacao) WHERE s.Title STARTS WITH '3225/2025' RETURN r.texto_completo`.
            4. Para buscar por ID de solicitação (ex: 99797), filtre a propriedade `id` do nó `Solicitacao` com `toFloat()`. Exemplo: `MATCH (s:Solicitacao) WHERE toFloat(s.id) = 99797.0 RETURN s.descricao`.
            5. Para buscar por status (ex: 'Aberta', 'RECUSADO'), use `toLower()` na propriedade `status` do nó `Solicitacao`. Exemplo: `MATCH (s:Solicitacao) WHERE toLower(s.status) = 'recusado' RETURN count(s)`.
            6. Para buscar por código de manual (ex: 'UCS0083'), filtre a propriedade `codigo_ucs` no nó `:Manual`. Exemplo: `MATCH (m:Manual) WHERE m.codigo_ucs = 'UCS0083' RETURN m.texto_completo`.
            7. Para buscar por 'Regra de Negócio' ou 'RN' (ex: 'RN001'), combine buscas com `AND`. Exemplo: `MATCH (m:Manual) WHERE m.texto_completo CONTAINS 'RN001' AND m.texto_completo CONTAINS 'Proposta de Consignação' RETURN m.texto_completo`.
            8. Se a pergunta for sobre RCMs de um cliente, primeiro encontre as solicitações do cliente e depois as RCMs relacionadas. Exemplo: `MATCH (r:RCM)-[:ORIGINADO_DE]->(s:Solicitacao)-[:ASSOCIADA_A]->(c:Cliente) WHERE toLower(c.nome) = 'alesc' RETURN r.id`.

            Pergunta Original: {question}
            """
            # 1. Gera a consulta Cypher
            cypher_response = cypher_chain.invoke(
                {"schema": graph.get_schema, "question": enhanced_question}
            )
            # Garantimos que o conteúdo seja uma string para o Pylance
            generated_cypher = cast("str", cypher_response.content)
            logging.info(f"Cypher Gerado: {generated_cypher}")
            # 2. Executa a consulta diretamente no grafo
            result = graph.query(generated_cypher)
            # 3. Retorna o resultado bruto como uma string JSON
            return json.dumps(result)
        except Exception as e:
            return f"Erro ao executar a consulta: {e!s}"

    factual_tool = Tool(
        name="Factual_Question_Answering",
        func=run_qa_chain,
        description="""Útil para responder perguntas factuais que buscam IDs, nomes, números, listas ou contagens.
Use esta ferramenta para perguntas sobre solicitações, RCMs, clientes e seus relacionamentos.
Exemplos de entrada: 'Qual o ID da solicitação 3225/2025?', 'Liste as 5 últimas solicitações do cliente Alesc', 'Quantas RCMs existem para o cliente UDESC?'""",
    )

    # Fornece ao agente AMBAS as ferramentas
    agent_executor = build_agent(llm, [semantic_tool, factual_tool])

    print("\n--- Assistente de Consulta SYSRH (Agente) ---")
    print("Digite 'sair' para terminar.")
    while True:
        question = input("\nFaça sua pergunta: ")
        if question.lower() == "sair":
            break
        try:
            response = agent_executor.invoke({"input": question})
            print(f"\nResposta Final: {response['output']}")
        except Exception as e:
            logging.exception("Erro ao executar o agente: %s", e)


if __name__ == "__main__":
    main()

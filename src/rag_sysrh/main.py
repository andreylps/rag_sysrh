import logging
import os

# import guardrails as gd
from dotenv import load_dotenv
from langchain_community.tools.tavily_search import TavilySearchResults
from langchain_community.vectorstores import Neo4jVector
from langchain_core.messages import HumanMessage
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.runnables import RunnablePassthrough
from langchain_core.tools import Tool
from langchain_neo4j import Neo4jGraph
from langchain_openai import ChatOpenAI, OpenAIEmbeddings

# from rag_sysrh.guardrails.rail_specs import rail_spec_cypher

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
        index_name="manual_chunks",
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
    # Atualizamos o prompt para solicitar JSON compatível com o Guardrail
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
10. **Verificação de Status (Human-in-the-Loop):** Ao buscar RCMs, verifique se a label `:NeedsRevision` está presente. Se sim, inclua uma coluna 'status_revisao' com o valor 'EM REVISÃO' no retorno. Exemplo: `MATCH (r:RCM) RETURN r.titulo, CASE WHEN 'NeedsRevision' IN labels(r) THEN 'EM REVISÃO' ELSE 'OK' END AS status_revisao`.

Schema:
{schema}

Pergunta: {input}

Responda APENAS com o JSON no formato: {{"cypher": "SUA_CONSULTA_AQUI"}}
"""  # noqa: E501
    )

    def run_qa_chain(question: str) -> str:
        """Executa a cadeia factual e retorna apenas a resposta."""
        try:
            # 1. Construção manual do prompt (bypass API issue)
            schema = graph.get_schema
            formatted_prompt = cypher_qa_prompt.format(schema=schema, input=question)

            # 2. Chamada ao LLM
            llm_response = llm.invoke([HumanMessage(content=formatted_prompt)]).content

            # 3. Limpeza do Markdown (Robustez)
            if "```json" in llm_response:
                llm_response = llm_response.split("```json")[1].split("```")[0].strip()
            elif "```" in llm_response:
                llm_response = llm_response.split("```")[1].split("```")[0].strip()

            # --- NOVA LÓGICA PARA EXTRAIR CYPHER DO JSON ---
            # O LLM foi instruído a retornar um JSON {"cypher": "..."}.
            # Precisamos fazer o parse desse JSON para obter a query real.
            try:
                import json

                response_json = json.loads(llm_response)
                if isinstance(response_json, dict) and "cypher" in response_json:
                    generated_cypher = response_json["cypher"]
                else:
                    # Se não for o JSON esperado, tenta usar a resposta pura como fallback
                    logging.warning(
                        "Resposta do LLM não está no formato JSON esperado. Tentando usar como string bruta."
                    )
                    generated_cypher = llm_response
            except json.JSONDecodeError:
                # Se falhar o parse do JSON, assume que o LLM retornou apenas a string (fallback)
                logging.warning(
                    "Falha ao fazer parse do JSON da resposta do LLM. Usando string bruta."
                )
                generated_cypher = llm_response
            # ------------------------------------------------

            if not generated_cypher:
                return "Erro ao extrair a consulta Cypher."

            # 5. Validação de Segurança Adicional (Hard Check)
            forbidden_keywords = [
                "CREATE",
                "DELETE",
                "DETACH",
                "MERGE",
                "SET",
                "REMOVE",
                "DROP",
                "ALTER",
            ]
            upper_cypher = generated_cypher.upper()
            for keyword in forbidden_keywords:
                if keyword in upper_cypher:
                    logging.warning(
                        f"Consulta Cypher bloqueada por conter '{keyword}': {generated_cypher}"
                    )
                    return f"A consulta foi bloqueada por motivos de segurança (operação de escrita '{keyword}' detectada)."

            logging.info(f"Cypher Validado e Seguro: {generated_cypher}")

            # 6. Execução
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
2.  **Custo por Ponto de Função:** Para chamados evolutivos, multiplique `s.effort` pelo valor do nó `:Custo {{tipo: 'ponto_funcao'}}`.
3.  **Custo por Hora:** Para os demais chamados, multiplique `s.horas_realizadas` pelo valor do nó `:Custo {{tipo: 'hora_desenvolvimento'}}`.
4.  **Exemplo para 'custo do chamado evolutivo 123'**: `MATCH (s:Solicitacao) WHERE s.id = 123 MATCH (c:Custo {{tipo:'ponto_funcao'}}) RETURN s.effort * c.valor AS custo_total`.
5.  **Exemplo para 'custo do chamado corretivo 456'**: `MATCH (s:Solicitacao) WHERE s.id = 456 MATCH (c:Custo {{tipo:'hora_desenvolvimento'}}) RETURN s.horas_realizadas * c.valor AS custo_total`.
6.  **Exemplo para 'custo do chamado 3225/2025' (buscando pelo title)**: `MATCH (s:Solicitacao) WHERE s.title = '3225/2025' MATCH (c:Custo) WHERE (s.tipo_solicitacao IN ['Evolutivo', 'Melhoria'] AND c.tipo = 'ponto_funcao') OR (NOT s.tipo_solicitacao IN ['Evolutivo', 'Melhoria'] AND c.tipo = 'hora_desenvolvimento') RETURN s.title AS chamado, CASE WHEN s.tipo_solicitacao IN ['Evolutivo', 'Melhoria'] THEN s.effort * c.valor ELSE s.horas_realizadas * c.valor END AS custo_total`.
7.  Se a pergunta especificar um cliente, filtre as solicitações por esse cliente antes de somar os custos.
8.  **Verificação de Inconsistência (Human-in-the-Loop):** Antes de calcular, verifique se a RCM tem a label `:DataInconsistency`. Se sim, retorne 'DADOS INCONSISTENTES' e não calcule o valor. Exemplo: `MATCH (s:Solicitacao) WHERE s.id = 123 RETURN CASE WHEN 'DataInconsistency' IN labels(s) THEN 'DADOS INCONSISTENTES' ELSE s.effort * 100 END AS custo`.
Schema:
{schema}

Pergunta: {input}

Responda APENAS com o JSON no formato: {{"cypher": "SUA_CONSULTA_AQUI"}}
"""  # noqa: E501
    )

    def run_billing_chain(question: str) -> str:
        """Executa a cadeia de faturamento e retorna o resultado."""
        try:
            # 1. Construção manual do prompt
            schema = graph.get_schema
            formatted_prompt = billing_cypher_prompt.format(
                schema=schema, input=question
            )

            # 2. Chamada ao LLM
            llm_response = llm.invoke([HumanMessage(content=formatted_prompt)]).content

            # 3. Limpeza do Markdown
            if "```json" in llm_response:
                llm_response = llm_response.split("```json")[1].split("```")[0].strip()
            elif "```" in llm_response:
                llm_response = llm_response.split("```")[1].split("```")[0].strip()

            # --- NOVA LÓGICA PARA EXTRAIR CYPHER DO JSON ---
            try:
                import json

                response_json = json.loads(llm_response)
                if isinstance(response_json, dict) and "cypher" in response_json:
                    generated_cypher = response_json["cypher"]
                else:
                    logging.warning(
                        "Resposta do LLM (Billing) não está no formato JSON esperado. Tentando usar como string bruta."
                    )
                    generated_cypher = llm_response
            except json.JSONDecodeError:
                logging.warning(
                    "Falha ao fazer parse do JSON da resposta do LLM (Billing). Usando string bruta."
                )
                generated_cypher = llm_response
            # ------------------------------------------------

            if not generated_cypher:
                return "Erro ao extrair a consulta Cypher de faturamento."

            # 5. Validação de Segurança Adicional
            forbidden_keywords = [
                "CREATE",
                "DELETE",
                "DETACH",
                "MERGE",
                "SET",
                "REMOVE",
                "DROP",
                "ALTER",
            ]
            upper_cypher = generated_cypher.upper()
            for keyword in forbidden_keywords:
                if keyword in upper_cypher:
                    logging.warning(
                        f"Consulta Cypher de faturamento bloqueada: {generated_cypher}"
                    )
                    return "A consulta foi bloqueada por segurança."

            logging.info(f"Cypher de Faturamento Validado: {generated_cypher}")

            # 6. Execução
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

    # --- FERRAMENTA 4: PESQUISA NA WEB ---
    # Este especialista responde a perguntas gerais usando a internet.
    tavily_tool = TavilySearchResults(max_results=3)
    web_search_tool = Tool(
        name="Web_Search",
        func=tavily_tool.run,
        description="""Útil para responder perguntas gerais, sobre eventos atuais ou tópicos não relacionados diretamente a SYSRH, clientes, manuais ou RCMs.
    Use esta ferramenta se as outras não souberem a resposta ou para obter informações do mundo real.
    Exemplos de entrada: 'Qual a capital da Austrália?', 'Quem ganhou o último campeonato de futebol?'""",
    )

    return [semantic_tool, factual_tool, billing_tool, web_search_tool]

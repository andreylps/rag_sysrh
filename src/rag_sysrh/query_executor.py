import logging
import os

from dotenv import load_dotenv
from langchain_neo4j import GraphCypherQAChain, Neo4jGraph
from langchain_openai import ChatOpenAI

# Configura o logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


def main() -> None:
    """
    Função principal para executar perguntas contra o grafo Neo4j usando RAG.
    """
    # Carrega as variáveis de ambiente (NEO4J_URI, NEO4J_USER, NEO4J_PASSWORD, OPENAI_API_KEY)  # noqa: E501
    load_dotenv()

    # Validação de que as chaves da API estão configuradas
    if not os.getenv("OPENAI_API_KEY"):
        logging.error("A variável de ambiente OPENAI_API_KEY não foi definida.")  # noqa: LOG015
        return

    # Conecta ao grafo Neo4j usando a integração da LangChain
    try:
        graph = Neo4jGraph(
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USER"),
            password=os.getenv("NEO4J_PASSWORD"),
            enhanced_schema=False,  # Adicione esta linha
        )
        logging.info("Conexão com o Neo4j estabelecida via LangChain.")  # noqa: LOG015
        # Opcional: Atualiza o schema para o LLM saber quais nós e relacionamentos existem  # noqa: E501
        graph.refresh_schema()
        logging.info("Schema do grafo atualizado.")  # noqa: LOG015
        logging.info("Schema detectado: %s", graph.schema)  # noqa: LOG015

    except Exception as e:
        logging.exception("Falha ao conectar ou atualizar o schema do Neo4j: %s", e)  # noqa: LOG015, TRY401
        return

    # Configura o LLM que será usado para traduzir a pergunta para Cypher
    llm = ChatOpenAI(model="gpt-4", temperature=0)

    # Cria a "Chain" de QA (Question Answering) da LangChain
    # Esta chain é o coração do processo de recuperação
    chain = GraphCypherQAChain.from_llm(
        graph=graph,
        llm=llm,
        verbose=True,
        allow_dangerous_requests=True,  # Adicionado para reconhecer o risco
    )

    # --- Loop para fazer perguntas ---
    print("\n--- Assistente de Consulta SYSRH ---")
    print("Digite 'sair' para terminar.")
    while True:
        question = input("\nFaça sua pergunta: ")
        if question.lower() == "sair":
            break

        # Adiciona instruções detalhadas (prompt engineering) para o LLM gerar Cypher mais robusto  # noqa: E501
        enhanced_question = f"""Usando o schema fornecido, responda à pergunta.
        Instruções importantes para a geração de Cypher:
        1. Se a pergunta envolver um Cliente, lembre-se que a direção do relacionamento é (Solicitacao)-[:ASSOCIADA_A]->(Cliente).
           Exemplo de consulta envolvendo cliente: `MATCH (s:Solicitacao)-[:ASSOCIADA_A]->(c:Cliente) WHERE toLower(c.nome) = 'alesc' RETURN s.id`.
        2. Se a pergunta usar um número de processo no formato 'XXXX/YYYY' (ex: "3225/2025"), ele se refere à propriedade `Title` do nó `Solicitacao`. Use a cláusula `STARTS WITH` para filtrar. Exemplo: `MATCH (s:Solicitacao) WHERE s.Title STARTS WITH '3225/2025' RETURN s`.
        3. Para filtrar pela propriedade 'id' de um nó 'Solicitacao' (que é um número simples, não 'XXXX/YYYY'), sempre use a função `toFloat()`. Exemplo: `WHERE toFloat(s.id) = 16361.0`.
        4. Para comparações de strings como 'nome' de Cliente ou 'status' de Solicitacao, sempre use a função `toLower()` para garantir que a busca não seja sensível a maiúsculas/minúsculas.
           Exemplo de filtro de nome: `WHERE toLower(c.nome) = 'alesc'`.
           Exemplo de filtro de status: `WHERE toLower(s.status) = 'aberta'`.
        5. Se a pergunta for sobre um procedimento, regra geral ou "como fazer" algo, ela provavelmente estará em um nó `:Manual`. Use a cláusula `CONTAINS` na propriedade `texto_completo` para encontrar a resposta. Exemplo: `MATCH (m:Manual) WHERE m.texto_completo CONTAINS 'férias' RETURN m.texto_completo`.
        6. Se a pergunta for sobre uma "Regra de Negócio" ou "RN" (ex: "RN001"), procure por esse termo exato (ex: "RN001") no texto completo de um nó `:Manual`. Exemplo: `MATCH (m:Manual) WHERE m.texto_completo CONTAINS 'RN001' RETURN m.texto_completo`.
        7. Para perguntas complexas com múltiplos critérios (ex: um tópico e uma regra), combine as buscas na cláusula `WHERE` usando `AND` para obter resultados mais precisos. Exemplo para "Qual a RN001 para Proposta de Consignação?": `MATCH (m:Manual) WHERE m.texto_completo CONTAINS 'Proposta de Consignação' AND m.texto_completo CONTAINS 'RN001' RETURN m.texto_completo`.
        8. **IMPORTANTE**: A consulta Cypher gerada NUNCA deve terminar com um ponto final (.) ou qualquer outra pontuação.

        Pergunta: {question}"""  # noqa: E501

        result = chain.invoke({"query": enhanced_question})
        print("\nResposta:")
        print(result["result"])


if __name__ == "__main__":
    main()

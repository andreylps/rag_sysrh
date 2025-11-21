import logging
from typing import Any, Dict

from langchain_core.prompts import PromptTemplate
from langchain_neo4j import GraphCypherQAChain

from rag_sysrh.base_agent import BaseAgent

# Configura o logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


class AgenteBI(BaseAgent):
    """
    Agente responsável por Business Intelligence e análise de dados.
    Permite consultas em linguagem natural sobre o grafo (Text-to-Cypher).
    """

    def __init__(self) -> None:
        super().__init__()
        self.chain = self._build_chain()

    def _build_chain(self) -> GraphCypherQAChain:
        """
        Constrói a cadeia GraphCypherQAChain para converter perguntas em Cypher.
        """
        cypher_generation_template = """Task:Generate Cypher statement to query a graph database.
Instructions:
Use only the provided relationship types and property keys.
Do not use any other relationship types or property keys that are not provided.
Schema:
{schema}
Note: Do not include any explanations or apologies in your responses.
Do not respond to any questions that might ask anything else than for you to construct a Cypher statement.
Do not include any text except the generated Cypher statement.
Examples: Here are a few examples of generated Cypher statements for particular questions:

# How many solicitations are there?
MATCH (s:Solicitacao) RETURN count(s)

# What are the solicitations with status 'Pendente'?
MATCH (s:Solicitacao {status: 'Pendente'}) RETURN s.title

The question is:
{question}"""

        cypher_prompt = PromptTemplate(
            input_variables=["schema", "question"],
            template=cypher_generation_template,
        )

        return GraphCypherQAChain.from_llm(
            llm=self.llm,
            graph=self.graph,
            verbose=True,
            cypher_prompt=cypher_prompt,
            allow_dangerous_requests=True,  # Necessário para permitir execução de Cypher
        )

    def responder_pergunta(self, pergunta: str) -> Dict[str, Any]:
        """
        Responde a uma pergunta em linguagem natural sobre os dados.
        Retorna um dicionário com a 'query' gerada e o 'result' final.
        """
        logging.info(f"AgenteBI recebendo pergunta: {pergunta}")
        try:
            # O GraphCypherQAChain retorna 'result' por padrão.
            # Para obter a query intermediária, precisaríamos de return_intermediate_steps=True
            # Vamos recriar a chain com essa opção se quisermos mostrar a query na UI.

            # Reconstruindo temporariamente para garantir acesso aos passos intermediários
            chain_with_steps = GraphCypherQAChain.from_llm(
                llm=self.llm,
                graph=self.graph,
                verbose=True,
                return_intermediate_steps=True,
                allow_dangerous_requests=True,
            )

            response = chain_with_steps.invoke({"query": pergunta})

            # response['intermediate_steps'] contém uma lista de tuplas/dicts.
            # Geralmente: [{'query': 'MATCH ...'}, {'context': ...}]
            # O formato exato depende da versão, mas geralmente o primeiro item é a query.

            generated_cypher = "N/A"
            if "intermediate_steps" in response:
                steps = response["intermediate_steps"]
                if steps and len(steps) > 0:
                    # O primeiro passo costuma ser a query gerada
                    first_step = steps[0]
                    if isinstance(first_step, dict) and "query" in first_step:
                        generated_cypher = first_step["query"]
                    elif isinstance(first_step, str):
                        generated_cypher = first_step

            return {"resposta": response["result"], "cypher": generated_cypher}

        except Exception as e:
            logging.error(f"Erro ao processar pergunta no AgenteBI: {e}")
            return {
                "resposta": f"Desculpe, não consegui analisar os dados. Erro: {e}",
                "cypher": "Erro na geração",
            }

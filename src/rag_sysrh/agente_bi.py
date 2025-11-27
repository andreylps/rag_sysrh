import logging
from typing import Any, Dict

from langchain_core.prompts import PromptTemplate
from langchain_neo4j import GraphCypherQAChain

from src.rag_sysrh.base_agent import BaseAgent

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
        try:
            self.chain = self._build_chain()
        except Exception as e:
            logging.error(f"Falha ao construir chain do AgenteBI: {e}")
            self.chain = None

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

    async def analisar_dados_json(self, dados: Dict[str, Any]) -> Dict[str, Any]:
        """
        Analisa um conjunto de dados já extraídos e gera insights em formato JSON.
        Não executa queries Cypher, apenas usa o LLM para interpretação.
        """
        import json

        from langchain_core.messages import HumanMessage, SystemMessage

        prompt_system = """
        Você é um Especialista em BI e Análise de Dados para um Dashboard Executivo.
        Sua tarefa é analisar os dados fornecidos e gerar um relatório JSON estrito.
        NÃO use markdown. NÃO inclua explicações fora do JSON.
        """

        prompt_user = f"""
        Analise os seguintes dados do dashboard:
        {json.dumps(dados, indent=2, ensure_ascii=False)}

        Gere um JSON com esta estrutura exata:
        {{
            "resumo": "Resumo executivo (max 2 frases)",
            "analiseProducao": {{
                "pontosFortes": ["Ponto 1", "Ponto 2"],
                "atencao": ["Ponto 1", "Ponto 2"]
            }},
            "analiseFinanceira": {{
                "insights": ["Insight 1", "Insight 2"]
            }},
            "recomendacoes": [
                {{ "titulo": "Ação", "descricao": "Detalhe" }}
            ],
            "alertas": [
                {{ "titulo": "Alerta", "descricao": "Detalhe", "tipo": "erro" }}
            ],
            "previsao": {{
                "metrica1Label": "Eficiência Est.",
                "metrica1Value": "00%",
                "metrica2Label": "Receita Est.",
                "metrica2Value": "R$ 00"
            }}
        }}
        """

        try:
            response = await self.llm.ainvoke(
                [
                    SystemMessage(content=prompt_system),
                    HumanMessage(content=prompt_user),
                ]
            )

            texto_resposta = response.content

            # Limpeza básica de markdown
            if "```json" in texto_resposta:
                texto_resposta = texto_resposta.split("```json")[1].split("```")[0]
            elif "```" in texto_resposta:
                texto_resposta = texto_resposta.split("```")[1].split("```")[0]

            return json.loads(texto_resposta)

        except Exception as e:
            logging.error(f"Erro na análise direta de JSON: {e}")
            return {
                "resumo": "Erro ao gerar análise.",
                "analiseProducao": {"pontosFortes": [], "atencao": []},
                "analiseFinanceira": {"insights": []},
                "recomendacoes": [],
                "alertas": [{"titulo": "Erro IA", "descricao": str(e), "tipo": "erro"}],
                "previsao": {},
            }

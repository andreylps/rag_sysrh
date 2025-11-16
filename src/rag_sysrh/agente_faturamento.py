import logging
import os
from typing import cast

from dotenv import load_dotenv
from langchain_core.prompts import ChatPromptTemplate
from langchain_neo4j import Neo4jGraph
from langchain_openai import ChatOpenAI
from pydantic import BaseModel, Field

# Configura o logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


class AnaliseRentabilidade(BaseModel):
    """
    Modelo de dados para a análise de rentabilidade de uma entrega.
    """

    custo_estimado: float = Field(
        description="O custo total estimado para a entrega, baseado nos pontos de função."  # noqa: E501
    )
    custo_realizado: float = Field(
        description="O custo real da entrega, baseado nas horas efetivamente trabalhadas."  # noqa: E501
    )
    rentabilidade_percentual: float = Field(
        description="A rentabilidade percentual, calculada como ((custo_estimado - custo_realizado) / custo_estimado) * 100."  # noqa: E501
    )
    parecer_analise: str = Field(
        description="Um breve parecer sobre a rentabilidade, destacando se a entrega foi lucrativa, ficou no zero a zero ou deu prejuízo."  # noqa: E501
    )


class PrevisaoFinanceira(BaseModel):
    """
    Modelo de dados para a previsão financeira baseada no backlog.
    """

    total_pontos_funcao: int = Field(
        description="Soma total dos pontos de função de todas as solicitações no backlog."  # noqa: E501
    )
    receita_potencial_total: float = Field(
        description="Receita potencial total calculada a partir dos pontos de função e do valor por PF."  # noqa: E501
    )
    numero_solicitacoes: int = Field(
        description="Número total de solicitações evolutivas no backlog."
    )
    resumo_executivo: str = Field(
        description="Um resumo executivo da previsão, destacando os principais projetos e o potencial financeiro."  # noqa: E501
    )


class AgenteFaturamento:
    """
    Agente autônomo para analisar a rentabilidade das entregas.
    """

    def __init__(self) -> None:
        load_dotenv()
        self.llm = ChatOpenAI(model="gpt-4-turbo", temperature=0)
        self.graph = Neo4jGraph(
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
        )

    def _buscar_entregas_para_analise(self) -> list[dict]:
        """Busca RCMs concluídos que ainda não foram analisados quanto à rentabilidade."""  # noqa: E501
        logging.info("Buscando entregas concluídas para análise de rentabilidade...")  # noqa: LOG015
        # Esta query assume que o RCM tem as propriedades 'pontos_funcao' e 'horas_realizadas'  # noqa: E501
        # e que existem nós :Custo com os valores para 'ponto_funcao' e 'hora_desenvolvimento'.  # noqa: E501
        # A análise de rentabilidade (PF vs Horas) aplica-se apenas a chamados evolutivos.  # noqa: E501
        query = """
        MATCH (rcm:RCM)-[:ORIGINADO_DE]->(s:Solicitacao)
        WHERE toLower(rcm.status) IN ['concluído', 'entregue', 'aceite produção']
          AND (toLower(s.tipo_solicitacao) = 'evolutivo' OR toLower(s.tipo_solicitacao) = 'melhoria')
          AND rcm.pontos_funcao IS NOT NULL
          AND rcm.horas_realizadas IS NOT NULL
          AND NOT (rcm)-[:TEM_ANALISE_DE]->(:AnaliseRentabilidade)
        // Busca os custos de PF e Hora
        MATCH (custo_pf:Custo {tipo: 'ponto_funcao'}) // Custo de venda
        MATCH (custo_hora:Custo {tipo: 'hora_desenvolvimento'})
        RETURN
            rcm.id AS rcm_id,
            rcm.pontos_funcao AS pontos_funcao,
            rcm.horas_realizadas AS horas_realizadas,
            custo_pf.valor AS valor_pf,
            custo_hora.valor AS valor_hora
        LIMIT 5
        """  # noqa: E501
        return self.graph.query(query)

    def _analisar_rentabilidade(
        self,
        pontos_funcao: float,
        horas_realizadas: float,
        valor_pf: float,
        valor_hora: float,
    ) -> AnaliseRentabilidade:
        """Usa um LLM para gerar a análise de rentabilidade."""
        structured_llm = self.llm.with_structured_output(AnaliseRentabilidade)
        prompt = ChatPromptTemplate.from_template(
            """Você é um Analista Financeiro especialista em projetos de software.
            Sua tarefa é analisar a rentabilidade de uma entrega com base nos dados fornecidos.

            **Dados da Entrega:**
            - Pontos de Função (Estimado): {pontos_funcao}
            - Horas Trabalhadas (Realizado): {horas_realizadas}
            - Valor por Ponto de Função: R$ {valor_pf}
            - Custo por Hora de Desenvolvimento: R$ {valor_hora}

            **Instruções:**
            1.  Calcule o `custo_estimado` (pontos_funcao * valor_pf).
            2.  Calcule o `custo_realizado` (horas_realizadas * valor_hora).
            3.  Calcule a `rentabilidade_percentual`.
            4.  Escreva um `parecer_analise` conciso sobre o resultado.
            """  # noqa: E501
        )
        chain = prompt | structured_llm
        return cast(
            "AnaliseRentabilidade",
            chain.invoke(
                {
                    "pontos_funcao": pontos_funcao,
                    "horas_realizadas": horas_realizadas,
                    "valor_pf": valor_pf,
                    "valor_hora": valor_hora,
                }
            ),
        )

    def _registrar_analise_rentabilidade(
        self, rcm_id: int, analise: AnaliseRentabilidade
    ) -> None:
        """Salva o resultado da análise de rentabilidade no grafo."""
        logging.info(f"Registrando análise de rentabilidade para o RCM ID {rcm_id}...")  # noqa: G004, LOG015
        query = """
        MATCH (rcm:RCM {id: $rcm_id})
        CREATE (ar:AnaliseRentabilidade $props)
        MERGE (rcm)-[:TEM_ANALISE_DE]->(ar)
        """
        params = {"rcm_id": rcm_id, "props": analise.dict()}
        self.graph.query(query, params=params)

    def _buscar_backlog_evolutivo(self) -> list[dict]:
        """Busca o backlog de solicitações evolutivas com estimativa de esforço."""
        logging.info("Buscando backlog evolutivo para previsão financeira...")  # noqa: LOG015
        # A query assume que o tipo da solicitação está na propriedade 'tipo_solicitacao'  # noqa: E501
        query = """
        MATCH (s:Solicitacao)
        WHERE (toLower(s.tipo_solicitacao) = 'evolutivo' OR toLower(s.tipo_solicitacao) = 'melhoria')
          AND NOT toLower(s.status) IN ['concluído', 'entregue', 'cancelado', 'aceite produção']
          AND s.effort IS NOT NULL AND s.effort > 0
        WITH collect({id: s.id, titulo: s.title, pontos_funcao: s.effort}) AS backlog
        // Se não houver backlog, a query para aqui e retorna uma lista vazia
        WHERE size(backlog) > 0
        MATCH (custo_pf:Custo {tipo: 'ponto_funcao'})
        RETURN backlog, custo_pf.valor AS valor_pf
        """  # noqa: E501
        return self.graph.query(query)

    def _gerar_previsao_financeira(
        self, backlog: list[dict], valor_pf: float
    ) -> PrevisaoFinanceira:
        """Usa um LLM para analisar o backlog e gerar uma previsão financeira."""
        structured_llm = self.llm.with_structured_output(PrevisaoFinanceira)
        prompt = ChatPromptTemplate.from_template(
            """Você é um Diretor Financeiro (CFO) especialista em TI.
            Sua tarefa é criar uma previsão financeira com base no backlog de solicitações evolutivas.

            **Dados do Backlog:**
            {backlog}

            **Valor por Ponto de Função:** R$ {valor_pf}

            **Instruções:**
            1.  Calcule o `total_pontos_funcao` somando os PFs de todos os itens do backlog.
            2.  Calcule a `receita_potencial_total` multiplicando o total de PFs pelo valor por PF.
            3.  Conte o `numero_solicitacoes` no backlog.
            4.  Escreva um `resumo_executivo` que apresente a previsão de forma clara para a gestão, destacando o potencial de receita e, se possível, mencionando 1 ou 2 dos projetos mais relevantes (com mais PFs).
            """  # noqa: E501
        )
        chain = prompt | structured_llm
        return cast(
            "PrevisaoFinanceira",
            chain.invoke({"backlog": backlog, "valor_pf": valor_pf}),
        )

    def _registrar_previsao_financeira(self, previsao: PrevisaoFinanceira) -> None:
        """Salva a previsão financeira gerada no grafo."""
        logging.info("Registrando nova previsão financeira no grafo...")  # noqa: LOG015
        query = """
        CREATE (p:PrevisaoFinanceira $props)
        SET p.data_geracao = datetime()
        """
        self.graph.query(query, params={"props": previsao.dict()})

    def executar_ciclo(self) -> str | None:
        """Executa um ciclo completo de análise de rentabilidade."""
        # Verifica se os dados necessários para as análises existem
        has_rcm_data = self.graph.query("MATCH (n:RCM) RETURN n LIMIT 1")
        if not has_rcm_data:
            return (
                "💰 Dados insuficientes para o Agente de Faturamento! Para análises de rentabilidade e previsões financeiras, é necessário o arquivo de RCMs.\n"  # noqa: E501
                "   - 📂 **Arquivo**: `rcms.csv`\n"
                "     **Descrição**: Contém os dados das Requisições de Mudança (RCMs) para cálculo de custos e receitas.\n"  # noqa: E501
                "     **Colunas essenciais**: `id`, `id_solicitacao`, `status`, `pontos_funcao` (para estimativa de receita) e `horas_realizadas` (para custo real)."  # noqa: E501
            )

        # --- Ciclo 1: Análise de Rentabilidade de Entregas Concluídas ---
        entregas = self._buscar_entregas_para_analise()
        if not entregas:
            logging.info("Nenhuma nova entrega para analisar a rentabilidade.")  # noqa: LOG015
        else:
            for entrega in entregas:
                analise = self._analisar_rentabilidade(
                    entrega["pontos_funcao"],
                    entrega["horas_realizadas"],
                    entrega["valor_pf"],
                    entrega["valor_hora"],
                )
                self._registrar_analise_rentabilidade(entrega["rcm_id"], analise)
            logging.info("Ciclo de análise de rentabilidade concluído.")  # noqa: LOG015

        # --- Ciclo 2: Geração de Previsão Financeira do Backlog ---
        dados_previsao = self._buscar_backlog_evolutivo()
        if not dados_previsao:
            logging.info("Nenhum backlog evolutivo encontrado para gerar previsão.")  # noqa: LOG015
        else:
            # A query retorna uma lista com um único dicionário
            dados = dados_previsao[0]
            previsao = self._gerar_previsao_financeira(
                dados["backlog"], dados["valor_pf"]
            )
            self._registrar_previsao_financeira(previsao)
            logging.info("Ciclo de previsão financeira concluído.")  # noqa: LOG015
        return None


if __name__ == "__main__":
    agente = AgenteFaturamento()
    agente.executar_ciclo()

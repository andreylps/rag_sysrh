import logging
from typing import Any, Dict, List, Optional

from langchain_core.prompts import (  # type: ignore
    ChatPromptTemplate,  # pyright: ignore[reportMissingImports]
)
from pydantic import BaseModel, Field  # pyright: ignore[reportMissingImports]

from rag_sysrh.base_agent import BaseAgent

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


class FaturamentoMensal(BaseModel):
    """Modelo para um ponto de dado de faturamento mensal, realizado ou previsto."""

    mes: str = Field(description="Mês e ano da análise (formato YYYY-MM).")
    valor: float = Field(description="Valor total faturado ou previsto para o mês.")
    tipo: str = Field(description="Tipo de dado: 'Realizado' ou 'Previsto'.")


class RentabilidadeEntrega(BaseModel):
    """Modelo para os dados de rentabilidade de uma única entrega."""

    rcm_id: str = Field(description="ID da RCM analisada.")
    custo_estimado: float = Field(description="Custo que foi estimado para a entrega.")
    custo_realizado: float = Field(description="Custo real da entrega.")


class RelatorioFaturamento(BaseModel):
    """
    Modelo para a saída completa do relatório de faturamento, contendo
    dados para gráficos e a análise textual do LLM.
    """

    dados_predicao_grafico: List[FaturamentoMensal] = Field(
        description="Lista de dados mensais para a geração do gráfico comparativo."
    )
    dados_rentabilidade_grafico: List[RentabilidadeEntrega] = Field(
        description="Lista de dados de rentabilidade (custo estimado vs. realizado) para o gráfico."
    )
    insights_historico: str = Field(
        description="Análise e insights sobre o desempenho dos últimos 3 meses."
    )
    analise_preditiva: str = Field(
        description="Análise preditiva para os próximos 3 meses, com justificativas."
    )


class AgenteFaturamento(BaseAgent):
    """
    Agente autônomo para analisar a rentabilidade das entregas.
    """

    def executar_ciclo_rentabilidade(self) -> None:
        """
        Executa um ciclo que busca RCMs concluídas, analisa sua rentabilidade
        e registra os resultados no grafo.
        """
        logging.info("Iniciando ciclo de análise de rentabilidade...")

        custos = self._buscar_custos_operacionais()
        if not custos:
            logging.error(
                "Não foi possível ler os custos operacionais. Abortando ciclo de rentabilidade."
            )
            return

        valor_pf = custos.get("ponto_funcao")
        valor_hora = custos.get("hora_desenvolvimento")

        if valor_pf is None or valor_hora is None:
            logging.error(
                "Os nós :Custo com tipo 'ponto_funcao' e 'hora_desenvolvimento' devem existir no grafo."
            )
            return

        entregas = self._buscar_entregas_para_analise()
        if not entregas:
            logging.info("Nenhuma nova entrega para analisar a rentabilidade.")
            return

        logging.info(f"Encontradas {len(entregas)} entregas para análise.")
        for entrega in entregas:
            # --- SANITY CHECK (Human-in-the-Loop) ---
            # Verifica se os dados fazem sentido antes de calcular.
            # Um chamado concluído não pode ter 0 horas ou 0 pontos de função (se evolutivo).
            pf = entrega.get("pontos_funcao", 0)
            horas = entrega.get("horas_realizadas", 0)

            if (
                horas == 0 or (pf == 0 and horas > 0)
            ):  # Assumindo que se tem horas, deveria ter PF se for evolutivo, ou vice-versa. Ajuste conforme regra de negócio.
                # Simplificação: Se horas == 0 em um chamado concluído, é inconsistente.
                if horas == 0:
                    logging.warning(
                        f"RCM {entrega['rcm_id']} tem 0 horas realizadas. Marcando como inconsistente."
                    )
                    self.graph.query(
                        "MATCH (rcm:RCM {id: $rcm_id}) SET rcm:DataInconsistency",
                        params={"rcm_id": entrega["rcm_id"]},
                    )
                    continue  # Pula para a próxima entrega

            # O método _analisar_rentabilidade agora recebe os custos lidos do arquivo
            analise = self._analisar_rentabilidade(
                entrega["pontos_funcao"],
                entrega["horas_realizadas"],
                valor_pf,
                valor_hora,
            )
            self._registrar_analise_rentabilidade(entrega["rcm_id"], analise)

        logging.info("Ciclo de análise de rentabilidade concluído.")

    def _buscar_entregas_para_analise(self, limit: int = 5) -> List[Dict[str, Any]]:
        """Busca RCMs concluídos que ainda não foram analisados quanto à rentabilidade."""  # noqa: E501
        logging.info("Buscando entregas concluídas para análise de rentabilidade...")  # noqa: LOG015
        # Esta query assume que o RCM tem as propriedades 'pontos_funcao' e 'horas_realizadas'  # noqa: E501
        # e que existem nós :Custo com os valores para 'ponto_funcao' e 'hora_desenvolvimento'.  # noqa: E501
        # A análise de rentabilidade (PF vs Horas) aplica-se apenas a chamados evolutivos.  # noqa: E501
        query = """
        MATCH (rcm:RCM)
        // Garante que as propriedades necessárias existem e são válidas
        WHERE toLower(toString(rcm.status)) IN ['concluído', 'entregue', 'aceite produção'] 
          AND rcm.pontos_funcao IS NOT NULL
          AND NOT (rcm)-[:TEM_ANALISE_DE]->(:AnaliseRentabilidade)
        RETURN
            rcm.id AS rcm_id,
            coalesce(rcm.pontos_funcao, 0) AS pontos_funcao,
            coalesce(rcm.horas_reais, 0) AS horas_realizadas
        LIMIT $limit
        """  # noqa: E501
        return self.graph.query(query, params={"limit": limit})

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
        return chain.invoke(
            {
                "pontos_funcao": pontos_funcao,
                "horas_realizadas": horas_realizadas,
                "valor_pf": valor_pf,
                "valor_hora": valor_hora,
            }
        )

    def _registrar_analise_rentabilidade(
        self, rcm_id: int, analise: AnaliseRentabilidade
    ) -> None:
        """Salva o resultado da análise de rentabilidade no grafo."""
        logging.info(f"Registrando análise de rentabilidade para o RCM ID {rcm_id}...")  # noqa: G004, LOG015
        query = """
        MATCH (rcm:RCM {id: $rcm_id})
        // Cria o nó de análise e adiciona um timestamp de geração
        CREATE (ar:AnaliseRentabilidade $props)
        SET ar.data_geracao = datetime()
        MERGE (rcm)-[:TEM_ANALISE_DE]->(ar)
        """
        params = {"rcm_id": rcm_id, "props": analise.model_dump()}
        self.graph.query(query, params=params)

    def _buscar_backlog_evolutivo(self) -> List[Dict[str, Any]]:
        """Busca o backlog de solicitações evolutivas com estimativa de esforço."""
        logging.info("Buscando backlog evolutivo para previsão financeira...")  # noqa: LOG015
        # A query assume que o tipo da solicitação está na propriedade 'tipo_solicitacao'  # noqa: E501
        query = """
        MATCH (s:Solicitacao)
        // Garante que as propriedades necessárias existem
        WHERE s.tipo_solicitacao IS NOT NULL AND s.status IS NOT NULL
          AND toLower(toString(s.tipo_solicitacao)) IN ['evolutivo', 'melhoria']
          AND NOT toLower(toString(s.status)) IN [ 
            'concluído', 'entregue', 'cancelado', 'aceite produção'
          ]
          AND s.effort IS NOT NULL AND s.effort > 0
        RETURN {id: s.id, titulo: s.title, pontos_funcao: s.effort} AS item
        """  # noqa: E501
        results = self.graph.query(query)
        return [result["item"] for result in results] if results else []

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
        return chain.invoke({"backlog": str(backlog), "valor_pf": valor_pf})

    def _registrar_previsao_financeira(self, previsao: PrevisaoFinanceira) -> None:
        """Salva a previsão financeira gerada no grafo."""
        logging.info("Registrando nova previsão financeira no grafo...")  # noqa: LOG015
        query = """
        CREATE (p:PrevisaoFinanceira $props)
        SET p.data_geracao = datetime()
        """
        self.graph.query(query, params={"props": previsao.model_dump()})

    def _buscar_custos_operacionais(self) -> Optional[Dict[str, float]]:
        """
        Busca os valores de custo do grafo.
        Retorna um dicionário mapeando o tipo de custo ao seu valor.
        """
        logging.info("Buscando custos operacionais do grafo...")
        query = "MATCH (c:Custo) RETURN c.tipo AS tipo, c.valor AS valor"
        results = self.graph.query(query)
        if not results:
            return None
        return {item["tipo"]: item["valor"] for item in results}

    def _buscar_dados_rentabilidade(self, limit: int = 10) -> List[Dict[str, Any]]:
        """Busca os dados de custo estimado vs. realizado das últimas análises."""
        logging.info("Buscando dados históricos de rentabilidade...")
        query = """
        MATCH (rcm:RCM)-[:TEM_ANALISE_DE]->(ar:AnaliseRentabilidade)
        RETURN
            rcm.id AS rcm_id,
            ar.custo_estimado AS custo_estimado,
            ar.custo_realizado AS custo_realizado
        ORDER BY ar.data_geracao DESC
        LIMIT $limit
        """
        return self.graph.query(query, params={"limit": limit})

    def _buscar_metas_de_faturamento(self) -> Optional[List[Dict[str, Any]]]:
        """
        Busca as metas de faturamento mensais do grafo.
        Retorna uma lista de dicionários com 'mes' e 'meta'.
        """
        logging.info("Buscando metas de faturamento do grafo...")
        query = "MATCH (m:MetaFaturamento) RETURN m.mes AS mes, m.meta AS meta"
        return self.graph.query(query)

    def _buscar_faturamento_historico(self, meses: int = 3) -> List[Dict[str, Any]]:
        """Busca o faturamento realizado (custo estimado) dos últimos meses."""
        logging.info(f"Buscando faturamento realizado dos últimos {meses} meses...")
        query = """
        MATCH (ar:AnaliseRentabilidade)
        WHERE ar.data_geracao >= date() - duration({months: $meses})
        WITH date.truncate('month', ar.data_geracao) AS mes, ar.custo_estimado AS faturamento
        RETURN mes, sum(faturamento) AS valor_total
        ORDER BY mes
        """
        return self.graph.query(query, params={"meses": meses})

    def _buscar_previsao_futura(self, meses: int = 3) -> List[Dict[str, Any]]:
        """Busca a previsão de faturamento dos próximos meses com base nas entregas previstas."""
        logging.info(
            f"Buscando previsão de faturamento para os próximos {meses} meses..."
        )
        query = """
        MATCH (de:DetalhesEvolutiva)
        WHERE de.data_prevista_entrega IS NOT NULL
        WITH date(de.data_prevista_entrega) AS data_entrega, 
             de.estimativa_pontos_funcao AS pf
        WHERE data_entrega >= date() 
          AND data_entrega < date() + duration({months: $meses})
        MATCH (c:Custo {tipo: 'ponto_funcao'})
        WITH date.truncate('month', data_entrega) AS mes, sum(pf * c.valor) AS valor_total
        RETURN mes, valor_total
        ORDER BY mes
        """
        return self.graph.query(query, params={"meses": meses})

    def _buscar_exemplos_de_calculo(self, limit: int = 3) -> List[Dict[str, Any]]:
        """Busca exemplos de cálculo de faturamento para usar como referência."""
        logging.info("Buscando exemplos de cálculo de faturamento do grafo...")
        query = """
        MATCH (e:ExemploCalculoFaturamento)
        RETURN e.chamado_id AS chamado, e.descricao AS descricao, e.pontos_funcao AS pf, e.valor_calculado AS valor, e.observacao AS obs
        LIMIT $limit
        """
        return self.graph.query(query, params={"limit": limit})

    def _gerar_analise_preditiva_com_llm(
        self,
        dados_predicao: List[FaturamentoMensal],
        dados_rentabilidade: List[RentabilidadeEntrega],
        metas: Optional[List[Dict[str, Any]]],
        exemplos_calculo: List[Dict[str, Any]],
    ) -> RelatorioFaturamento:
        """Usa o LLM para gerar insights e análise preditiva sobre os dados de faturamento."""
        structured_llm = self.llm.with_structured_output(RelatorioFaturamento)

        prompt = ChatPromptTemplate.from_template(
            """Você é um Analista Financeiro Sênior (CFO). Sua tarefa é analisar dados de faturamento e rentabilidade para fornecer um relatório estratégico completo.

            **Dados para Gráfico de Predição (Realizado vs. Previsto):**
            {dados_predicao_str}

            **Dados para Gráfico de Rentabilidade (Estimado vs. Realizado):**
            {dados_rentabilidade_str}

            **Metas de Faturamento Mensal (se disponível):**
            {metas_str}

            **Exemplos de Referência de Cálculos Anteriores:**
            {exemplos_calculo_str}

            **Instruções:**
            1.  **Retorne os Dados para os Gráficos:** Preencha os campos `dados_predicao_grafico` e `dados_rentabilidade_grafico` com os dados fornecidos, sem alterá-los.
            2.  **Gere Insights do Histórico:** Analise os dados 'Realizado' dos últimos 3 meses. Identifique tendências (crescimento, queda, estabilidade), compare os meses e destaque qualquer anomalia. Use os exemplos de referência para contextualizar a relação entre pontos de função e valor, se relevante. Escreva essa análise no campo `insights_historico`.
            3.  **Gere Análise Preditiva:** Analise os dados 'Previsto' para os próximos 3 meses. Compare a previsão com o desempenho histórico. Aponte se a previsão é otimista ou pessimista e justifique com base nos dados. Se houver metas, avalie se as previsões estão alinhadas para atingi-las. Forneça recomendações estratégicas (ex: "O faturamento previsto para o próximo mês está abaixo da meta, sugerimos focar em fechar novos projetos do backlog evolutivo."). Escreva essa análise no campo `analise_preditiva`.
            """  # noqa: E501
        )

        chain = prompt | structured_llm
        return chain.invoke(
            {
                "dados_predicao_str": str(dados_predicao),
                "dados_rentabilidade_str": str(dados_rentabilidade),
                "metas_str": str(metas) if metas else "Nenhuma meta fornecida.",
                "exemplos_calculo_str": str(exemplos_calculo),
            }
        )

    def _buscar_rcms_inconsistentes(self) -> List[Dict[str, Any]]:
        """Busca RCMs marcadas com :DataInconsistency."""
        logging.info("Buscando RCMs com dados inconsistentes...")
        query = """
        MATCH (rcm:RCM:DataInconsistency)
        RETURN rcm.id AS rcm_id, rcm.status AS status
        """
        return self.graph.query(query)

    def gerar_relatorio_completo(self) -> RelatorioFaturamento:
        """
        Orquestra a análise de faturamento, buscando dados históricos e futuros,
        e gerando uma análise preditiva completa.
        """
        logging.info(
            "Iniciando ciclo completo de geração de relatório de faturamento..."
        )

        # Passo 1: Executa o ciclo de rentabilidade para garantir que os dados históricos estejam atualizados.
        logging.info("Etapa 1: Analisando rentabilidade de entregas recentes...")
        self.executar_ciclo_rentabilidade()

        # Passo 2: Buscar todos os dados necessários para o relatório.
        logging.info("Etapa 2: Coletando dados para o relatório preditivo...")
        faturamento_historico = self._buscar_faturamento_historico(meses=3)
        rentabilidade_historica = self._buscar_dados_rentabilidade()
        metas = self._buscar_metas_de_faturamento()
        faturamento_previsto = self._buscar_previsao_futura(meses=3)
        exemplos_calculo = self._buscar_exemplos_de_calculo()
        inconsistentes = self._buscar_rcms_inconsistentes()

        # 2. Formatar os dados para o modelo Pydantic
        dados_compilados_predicao = []
        for item in faturamento_historico:
            dados_compilados_predicao.append(
                FaturamentoMensal(
                    mes=item["mes"].iso_format(),
                    valor=item["valor_total"],
                    tipo="Realizado",
                )
            )

        for item in faturamento_previsto:
            dados_compilados_predicao.append(
                FaturamentoMensal(
                    mes=item["mes"].iso_format(),
                    valor=item["valor_total"],
                    tipo="Previsto",
                )
            )

        dados_compilados_rentabilidade = [
            RentabilidadeEntrega(**item) for item in rentabilidade_historica
        ]

        if not dados_compilados_predicao and not dados_compilados_rentabilidade:
            logging.warning("Nenhum dado de faturamento encontrado para análise.")
            insights_historico = "Nenhum dado histórico de rentabilidade encontrado. Execute o ciclo de rentabilidade após marcar RCMs como 'Concluído' para gerar esses dados."
            analise_preditiva = "Nenhuma previsão de faturamento pôde ser gerada. Execute a 'Análise de Solicitação' para demandas do tipo 'Melhoria' para criar previsões de entrega."

            if inconsistentes:
                lista_inc = ", ".join([i["rcm_id"] for i in inconsistentes])
                insights_historico += f"\n\n⚠️ **ATENÇÃO:** Foram encontradas RCMs com dados inconsistentes (ex: 0 horas): {lista_inc}. Verifique o cadastro."

            return RelatorioFaturamento(
                dados_predicao_grafico=[],
                dados_rentabilidade_grafico=[],
                insights_historico=insights_historico,
                analise_preditiva=analise_preditiva,
            )

        # Passo 3: Gerar a análise textual com o LLM.
        logging.info("Gerando insights e análise preditiva com o LLM...")

        # Adiciona alerta de inconsistência aos dados passados ao LLM, se houver
        dados_extras = {}
        if inconsistentes:
            lista_inc = ", ".join([i["rcm_id"] for i in inconsistentes])
            dados_extras["alerta_inconsistencia"] = (
                f"Existem RCMs ignoradas por dados inconsistentes: {lista_inc}."
            )

        # Modificamos a chamada para incluir o alerta no prompt (precisamos ajustar o prompt ou concatenar nos insights)
        # Como o prompt é fixo no método _gerar_analise_preditiva_com_llm, vamos injetar essa informação
        # concatenando com os exemplos ou criando um campo ad-hoc se fosse flexível.
        # A melhor abordagem sem mudar a assinatura do método auxiliar é tratar o retorno.

        relatorio_completo = self._gerar_analise_preditiva_com_llm(
            dados_predicao=dados_compilados_predicao,
            dados_rentabilidade=dados_compilados_rentabilidade,
            metas=metas,
            exemplos_calculo=exemplos_calculo,
        )

        # Injeta o alerta no texto gerado pelo LLM
        if inconsistentes:
            lista_inc = ", ".join([i["rcm_id"] for i in inconsistentes])
            alerta = f"\n\n⚠️ **DADOS INCONSISTENTES:** As seguintes RCMs foram ignoradas na análise por conterem dados inválidos (ex: 0 horas trabalhadas): {lista_inc}."
            relatorio_completo.insights_historico += alerta

        logging.info("Análise preditiva de faturamento concluída com sucesso.")
        # Garante que os dados para os gráficos sejam retornados corretamente
        relatorio_completo.dados_predicao_grafico = dados_compilados_predicao
        relatorio_completo.dados_rentabilidade_grafico = dados_compilados_rentabilidade

        return relatorio_completo


if __name__ == "__main__":
    agente = AgenteFaturamento()
    # Agora, apenas um método é necessário para gerar o relatório completo
    relatorio = agente.gerar_relatorio_completo()
    print(relatorio.model_dump_json(indent=2))

import logging
import os
import sys
from io import StringIO
from pathlib import Path
from typing import Any

import altair as alt  # type: ignore
import pandas as pd  # type: ignore
import streamlit as st  # type: ignore
from dotenv import load_dotenv  # type: ignore
from langchain_core.tools import Tool  # type: ignore
from langchain_neo4j import Neo4jGraph  # type: ignore
from langchain_openai import ChatOpenAI  # type: ignore

# --- Solução para o ImportError ---
# Adiciona o diretório 'src' ao sys.path para garantir que as importações funcionem
# independentemente de como o script é executado.
SRC_PATH = Path(__file__).resolve().parent.parent
if str(SRC_PATH) not in sys.path:
    sys.path.append(str(SRC_PATH))

from rag_sysrh.agent_executor import build_agent  # noqa: E402
from rag_sysrh.agente_documentacao import AgenteDocumentacao  # noqa: E402
from rag_sysrh.agente_faturamento import AgenteFaturamento  # noqa: E402
from rag_sysrh.agente_planejamento_rcm import AgentePlanejamentoRCM  # noqa: E402
from rag_sysrh.agente_qualidade import AgenteQualidade  # noqa: E402
from rag_sysrh.data_ingestion import DataIngestion  # noqa: E402
from rag_sysrh.guarded_workflow import guarded_app  # noqa: E402
from rag_sysrh.main import get_tools  # noqa: E402

# Configura o logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


@st.cache_resource
def initialize_graph() -> None:
    """
    Verifica se o grafo está vazio e, se estiver, executa a ingestão inicial.
    """
    try:
        graph = Neo4jGraph(
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
        )
        # Verifica se há algum nó no banco
        result = graph.query("MATCH (n) RETURN count(n) as count")
        node_count = result[0]["count"] if result else 0

        if node_count == 0:
            logging.info(
                "Banco de dados vazio detectado. Iniciando ingestão automática..."
            )
            ingestion = DataIngestion(
                data_directory="data",
                structured_data_path="data/solicitacoes.csv",
                rcm_data_path="data/rcms_01.csv",
                # Ajuste conforme necessário ou deixe None para processar todos
                single_manual_path=None,
            )
            ingestion.run_ingestion(clear_db=True)
            logging.info("Ingestão automática concluída.")
        else:
            logging.info(
                f"Banco de dados já populado com {node_count} nós. Pulando ingestão."
            )

    except Exception as e:
        logging.error(f"Falha na inicialização do grafo: {e}")


# --- FUNÇÕES DE CACHE PARA PERFORMANCE ---
@st.cache_resource
def load_tools() -> list[Tool]:
    """Carrega as ferramentas do agente e as armazena em cache."""
    return get_tools()


@st.cache_resource
def load_agente_documentacao() -> AgenteDocumentacao:
    """Carrega o agente de documentação e o armazena em cache."""
    return AgenteDocumentacao()


@st.cache_resource
def load_agente_planejamento_rcm() -> AgentePlanejamentoRCM:
    """Carrega o agente de planejamento de RCM e o armazena em cache."""
    return AgentePlanejamentoRCM()


class StreamlitLogHandler(logging.Handler):
    """
    Um handler de log que escreve os registros em um container do Streamlit.
    """

    def __init__(self, container: Any, log_stream: StringIO) -> None:
        super().__init__()
        self.container = container
        self.log_stream = log_stream

    def emit(self, record: logging.LogRecord) -> None:
        msg = self.format(record)
        self.log_stream.write(msg + "\n")
        self.container.code(self.log_stream.getvalue(), language="log")


@st.cache_resource
def carregar_dados_faturamento() -> None:
    """
    Lê os arquivos CSV de faturamento e os insere/atualiza no Neo4j.
    Garante que os dados de custo e metas estejam no grafo.
    """
    logging.info("Verificando e carregando dados de faturamento no Neo4j...")
    graph = Neo4jGraph(
        url=os.getenv("NEO4J_URI"),
        username=os.getenv("NEO4J_USERNAME"),
        password=os.getenv("NEO4J_PASSWORD"),
    )

    # Carrega os custos
    custos_path = "data/faturamento/custos.csv"
    if os.path.exists(custos_path):
        df_custos = pd.read_csv(custos_path)
        for _, row in df_custos.iterrows():
            graph.query(
                """
                MERGE (c:Custo {tipo: $tipo})
                SET c.valor = $valor
                """,
                params={"tipo": row["tipo"], "valor": row["valor"]},
            )
        logging.info("Dados de custos carregados/atualizados no Neo4j.")

    # Carrega as metas mensais
    metas_path = "data/faturamento/metas_mensais.csv"
    if os.path.exists(metas_path):
        df_metas = pd.read_csv(metas_path)
        for _, row in df_metas.iterrows():
            graph.query(
                "MERGE (m:MetaFaturamento {mes: $mes}) SET m.meta = $meta",
                params={"mes": row["mes"], "meta": row["meta"]},
            )
        logging.info("Dados de metas de faturamento carregados/atualizados no Neo4j.")

    # Carrega exemplos de cálculo de faturamento como base de conhecimento
    exemplos_path = "data/faturamento/exemplos_calculo_faturamento.csv"
    if os.path.exists(exemplos_path):
        df_exemplos = pd.read_csv(exemplos_path)
        # Converte todas as colunas para string para evitar problemas de tipo no Neo4j
        df_exemplos = df_exemplos.astype(str)
        for _, row in df_exemplos.iterrows():
            properties = row.to_dict()
            graph.query(
                """
                MERGE (e:ExemploCalculoFaturamento {chamado_id: $chamado_id})
                SET e += $properties
                """,
                params={"chamado_id": row["chamado_id"], "properties": properties},
            )
        logging.info("Base de conhecimento de faturamento carregada/atualizada.")


# --- INTERFACES DE RENDERIZAÇÃO ---


def render_chat_interface() -> None:
    """Renderiza a interface do chat conversacional."""
    st.subheader("💬 Chat Conversacional")
    st.write(
        "Faça perguntas sobre manuais, regras de negócio, solicitações ou clientes."
    )
    tools = load_tools()
    # Inicializa o agente e o histórico no estado da sessão
    if "agent_executor" not in st.session_state:
        st.session_state.agent_executor = build_agent(tools)
    if "chat_history" not in st.session_state:
        st.session_state.chat_history = []

    # Exibe as mensagens do histórico
    for author, message in st.session_state.chat_history:
        with st.chat_message(author, avatar="👤" if author == "user" else "🤖"):
            st.markdown(message)

    # Captura a entrada do usuário
    if prompt := st.chat_input("Qual a sua dúvida?"):
        # Adiciona a mensagem do usuário ao histórico e à tela
        st.session_state.chat_history.append(("user", prompt))
        with st.chat_message("user", avatar="👤"):
            st.markdown(prompt)

        # Gera e exibe a resposta do agente
        with st.chat_message("assistant", avatar="🤖"):  # noqa: SIM117
            with st.spinner("Analisando..."):
                try:
                    response = st.session_state.agent_executor.invoke({"input": prompt})
                    response_text = response.get(
                        "output", "Não consegui encontrar uma resposta."
                    )
                    st.markdown(response_text)
                    st.session_state.chat_history.append(("assistant", response_text))
                except Exception as e:  # noqa: BLE001
                    error_message = f"Ocorreu um erro: {e}"
                    st.error(error_message)
                    st.session_state.chat_history.append(("assistant", error_message))


def render_analysis_interface() -> None:
    """Renderiza a interface de análise de solicitação."""
    st.subheader("🔬 Análise de Solicitação")
    st.write(
        "Forneça o texto de uma solicitação para receber uma análise completa, incluindo diagnóstico, solução e estimativa."  # noqa: E501
    )

    # Inicializa o estado da sessão para o relatório
    if "relatorio_analise" not in st.session_state:
        st.session_state.relatorio_analise = None

    solicitacao_texto = st.text_area("Cole o texto da solicitação aqui:", height=150)

    if st.button("Analisar Solicitação"):
        if not solicitacao_texto:
            st.warning("Por favor, insira o texto da solicitação.")
        else:
            st.session_state.relatorio_analise = None  # Limpa o relatório anterior
            with st.spinner(
                "Executando workflow de análise... Isso pode levar um minuto."
            ):
                try:
                    # Chama o novo workflow com guardrail
                    final_state = guarded_app.invoke(
                        {"solicitacao_original": solicitacao_texto}
                    )
                    relatorio = final_state.get("final_report")
                    st.session_state.relatorio_analise = relatorio
                except Exception as e:  # noqa: BLE001
                    st.error(f"Ocorreu um erro durante a análise: {e}")

    # Exibe o relatório se ele existir no estado da sessão
    if st.session_state.relatorio_analise:
        relatorio = st.session_state.relatorio_analise
        st.markdown("---")
        st.markdown("### 📄 Relatório de Análise")

        # Seção de Análise Geral
        st.info(f"**Tipo do Problema:** {relatorio.tipo_problema}")
        st.info(f"**Tipo de Solicitação:** {relatorio.tipo_solicitacao}")
        st.success(f"**Resumo do Problema:** {relatorio.resumo_problema}")
        st.warning(f"**Diagnóstico Técnico:** {relatorio.diagnostico}")
        st.success(f"**Solução Sugerida:** {relatorio.solucao_sugerida}")

        # Seção de Esforço e Complexidade
        st.markdown("#### Análise de Esforço")
        col1, col2, col3 = st.columns(3)
        col1.metric(label="Complexidade", value=relatorio.complexidade)
        col2.metric(
            label="Esforço de Resolução",
            value=relatorio.esforco_resolucao_dias,
        )
        col3.metric(label="Nível de Esforço", value=relatorio.nivel_esforco)

        # Seção Específica para Demandas Evolutivas
        if relatorio.detalhes_evolutiva:
            st.markdown("#### Planejamento da Demanda Evolutiva")
            col1, col2, col3 = st.columns(3)
            col1.metric(
                label="Estimativa (Pontos de Função)",
                value=f"{relatorio.detalhes_evolutiva.estimativa_pontos_funcao} PF",  # noqa: E501
            )
            col2.metric(
                label="Prazo (Dias Úteis)",
                value=f"{relatorio.detalhes_evolutiva.prazo_dias_uteis} dias",  # noqa: E501
            )
            col3.metric(
                label="Data Prevista de Entrega",
                value=relatorio.detalhes_evolutiva.data_prevista_entrega,
            )

        # --- INTEGRAÇÃO DO NOVO AGENTE DE PLANEJAMENTO ---
        st.markdown("---")
        st.markdown("### 📋 Próximo Passo: Planejamento da RCM")
        if st.button("Gerar Plano de RCM Estruturado"):
            with st.spinner("O Agente de Planejamento está elaborando a RCM..."):
                try:
                    agente_planejamento = load_agente_planejamento_rcm()
                    plano_rcm = agente_planejamento.gerar_plano_rcm(relatorio)

                    if plano_rcm:
                        st.markdown("### Plano de RCM Gerado")
                        st.markdown(
                            agente_planejamento.formatar_plano_para_markdown(plano_rcm)
                        )

                        # --- Fluxo de Aprovação (Human-in-the-Loop) ---
                        st.warning(
                            "⚠️ Este plano está como 'Pendente Aprovação'. Revise antes de aprovar."
                        )

                        col1, col2 = st.columns(2)
                        with col1:
                            if st.button("✅ Aprovar Plano de RCM"):
                                with st.spinner("Oficializando RCM..."):
                                    try:
                                        agente_planejamento.aprovar_plano_rcm(
                                            plano_rcm.titulo_rcm
                                        )
                                        st.success(
                                            f"RCM '{plano_rcm.titulo_rcm}' aprovada e oficializada!"
                                        )
                                        st.balloons()
                                    except Exception as e:
                                        st.error(f"Erro ao aprovar RCM: {e}")
                        with col2:
                            if st.button("❌ Descartar Rascunho"):
                                st.info(
                                    "Rascunho descartado (funcionalidade de exclusão a implementar)."
                                )

                        # Salva o plano (como pendente) automaticamente ao gerar, ou poderia ser apenas ao aprovar.
                        # Pela lógica atual do agente, ele já salva no final do 'gerar_plano_rcm' se chamarmos o método de salvar.
                        # O código original do app.py chamava 'salvar_plano_rcm' logo após gerar?
                        # Vamos verificar o código original. Se não chamava, precisamos chamar.
                        # O código original do app.py (não mostrado aqui, mas inferido) provavelmente chamava salvar.
                        # Vamos assumir que o botão "Gerar Plano" já chama o salvar.
                        # Se não, deveríamos chamar aqui.
                        # Olhando o código anterior (não visível no diff), o app chamava:
                        # agente_planejamento.salvar_plano_rcm(plano_gerado, solicitacao_id)
                        # Vamos garantir que isso seja feito ANTES da aprovação, para que o nó exista.

                        # Como estamos dentro do bloco 'if plano_rcm', vamos salvar como pendente agora.
                        try:
                            # Precisamos do ID da solicitação. O código original pegava de 'solicitacao_selecionada'.
                            # Vamos assumir que 'solicitacao_selecionada' está disponível no escopo (estava no código original).
                            # O ID é a primeira parte da string "ID - Título"
                            # O relatorio já contém o solicitacao_id
                            agente_planejamento.salvar_plano_rcm(
                                plano_rcm, relatorio.solicitacao_id
                            )
                            st.toast(
                                "✅ Rascunho do Plano de RCM salvo no banco de dados!"
                            )
                        except Exception as e:
                            st.error(f"Erro ao salvar rascunho: {e}")

                except Exception as e:
                    st.error(f"Ocorreu um erro ao gerar o plano de RCM: {e}")


def render_dashboard_interface() -> None:
    """Renderiza a interface do Dashboard de Business Intelligence."""
    st.subheader("📊 Dashboard de Business Intelligence")
    st.write("Análise visual e insights sobre as solicitações do sistema.")

    try:
        graph = Neo4jGraph(
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
        )
    except Exception as e:  # noqa: BLE001
        st.error(f"Não foi possível conectar ao Neo4j para o dashboard: {e}")
        return

    # --- GERAÇÃO DOS GRÁFICOS ---
    col1, col2 = st.columns(2)

    with col1:
        st.markdown("#### Distribuição por Status")
        with st.spinner("Carregando dados..."):
            status_data = graph.query(
                "MATCH (s:Solicitacao) RETURN s.status AS status, count(s) AS quantidade"  # noqa: E501
            )
            if status_data:
                df_status = pd.DataFrame(status_data)
                chart_status = (
                    alt.Chart(df_status)
                    .mark_bar()
                    .encode(
                        x=alt.X("quantidade:Q", title="Quantidade"),
                        y=alt.Y("status:N", title="Status", sort="-x"),
                        tooltip=["status", "quantidade"],
                    )
                    .interactive()
                )
                st.altair_chart(
                    chart_status, use_container_width=True
                )  # Mantido conforme doc do altair, mas ciente do warning

    with col2:
        st.markdown("#### Carga por Responsável")
        with st.spinner("Carregando dados..."):
            responsavel_data = graph.query(
                """
                MATCH (s:Solicitacao)-[:ATRIBUIDA_A]->(r:Responsavel)
                RETURN r.nome AS responsavel, count(s) AS quantidade
                ORDER BY quantidade DESC LIMIT 10
                """
            )
            if responsavel_data:
                df_responsavel = pd.DataFrame(responsavel_data)
                chart_responsavel = (
                    alt.Chart(df_responsavel)
                    .mark_bar()
                    .encode(
                        x=alt.X("quantidade:Q", title="Quantidade de Solicitações"),
                        y=alt.Y("responsavel:N", title="Responsável", sort="-x"),
                        tooltip=["responsavel", "quantidade"],
                    )
                    .interactive()
                )
                st.altair_chart(
                    chart_responsavel, use_container_width=True
                )  # Mantido conforme doc do altair, mas ciente do warning

    # --- AGENTE ANALISTA DE BI ---
    st.markdown("---")
    st.markdown("### 🧠 Análise do Agente de BI")
    if st.button("Gerar Análise dos Dados"):
        with st.spinner("O agente de BI está analisando os gráficos..."):
            llm = ChatOpenAI(model="gpt-4-turbo", temperature=0)
            prompt = f"""Você é um analista de Business Intelligence. Sua tarefa é analisar os dados brutos dos gráficos e fornecer um resumo com pontos de atenção e sugestões.

            Dados de Distribuição por Status:
            {status_data}

            Dados de Carga de Trabalho por Responsável:
            {responsavel_data}

            Com base nesses dados, gere um resumo analítico com "Pontos de Atenção" e "Sugestões de Ação". Seja conciso e direto.
            """  # noqa: E501
            analise = llm.invoke(prompt).content
            st.info(analise)


def render_proactive_agents_interface() -> None:  # noqa: C901, PLR0912, PLR0915
    """Renderiza a interface para execução manual dos agentes proativos."""
    st.subheader("⚙️ Execução de Agentes Proativos")
    st.write(
        "Dispare manualmente os ciclos de análise dos agentes autônomos do sistema."
    )

    st.markdown("---")
    st.markdown("### Agente de Qualidade")
    st.write(
        "Monitora o ciclo de vida das solicitações, validando a qualidade da descrição, conformidade de RCMs, prazos e entregas."  # noqa: E501
    )

    if st.button("Executar Ciclo do Agente de Qualidade"):
        with st.status(
            "🧠 O Agente de Qualidade está pensando...", expanded=True
        ) as status:
            try:
                agente_qualidade = AgenteQualidade()
                # Executa o ciclo gerencial que retorna um relatório em Markdown
                relatorio_markdown = agente_qualidade.executar_ciclo_gerencial(
                    status_callback=lambda msg: status.update(label=f"🧠 {msg}")
                )
                st.markdown(relatorio_markdown)
            except Exception as e:  # noqa: BLE001
                st.error(
                    f"Ocorreu um erro durante a execução do Agente de Qualidade: {e}"
                )

    # Seção para simulação de dados para testes
    with st.expander("🔧 Ferramentas de Teste e Simulação"):
        st.write(
            "Use estes botões para simular eventos no sistema e gerar dados para os agentes."
        )
        if st.button("Simular Conclusão de RCM"):
            try:
                graph = Neo4jGraph(
                    url=os.getenv("NEO4J_URI"),
                    username=os.getenv("NEO4J_USERNAME"),
                    password=os.getenv("NEO4J_PASSWORD"),
                )
                # Encontra uma RCM que ainda não está concluída e a atualiza
                query = """
                MATCH (r:RCM) WHERE NOT toLower(toString(r.status)) = 'concluído'
                WITH r LIMIT 1
                SET r.status = 'Concluído'
                RETURN r.id AS rcm_id
                """
                result = graph.query(query)
                if result:
                    st.success(f"RCM '{result[0]['rcm_id']}' marcada como 'Concluído'!")
                else:
                    st.warning("Nenhuma RCM encontrada para simular a conclusão.")
            except Exception as e:
                st.error(f"Falha ao simular conclusão: {e}")

    st.markdown("---")
    st.markdown("### Agente de Faturamento")
    st.write(
        "Analisa a rentabilidade das entregas concluídas, comparando o custo estimado com o custo realizado."  # noqa: E501
    )

    if st.button("Gerar Relatório de Faturamento"):
        with st.status(
            "🧠 O Agente de Faturamento está trabalhando...", expanded=True
        ) as status:
            try:
                agente_faturamento = AgenteFaturamento()
                status.update(label="Analisando rentabilidade e gerando previsão...")
                relatorio = agente_faturamento.gerar_relatorio_completo()

                if relatorio and (
                    relatorio.dados_predicao_grafico
                    or relatorio.dados_rentabilidade_grafico
                ):
                    # Gráfico 1: Predição de Faturamento
                    df_predicao_raw = pd.DataFrame(
                        [d.model_dump() for d in relatorio.dados_predicao_grafico]
                    )
                    # O agente também busca as metas, mas elas não vêm no objeto de retorno.
                    # Por simplicidade, vamos buscá-las aqui também.
                    # Em uma evolução, poderiam ser adicionadas ao objeto RelatorioFaturamento.
                    graph = Neo4jGraph(
                        url=os.getenv("NEO4J_URI"),
                        username=os.getenv("NEO4J_USERNAME"),
                        password=os.getenv("NEO4J_PASSWORD"),
                    )
                    metas_data = graph.query(
                        "MATCH (m:MetaFaturamento) RETURN m.mes AS mes, m.meta AS meta"
                    )
                    df_metas = pd.DataFrame(metas_data)

                    status.update(label="Renderizando gráficos...")
                    st.markdown(
                        "#### Análise de Faturamento: Realizado vs. Previsto vs. Meta"
                    )
                    if not df_predicao_raw.empty:
                        # Pivotar os dados para o formato "wide"
                        df_pivot = df_predicao_raw.pivot(
                            index="mes", columns="tipo", values="valor"
                        ).reset_index()
                        df_pivot["mes"] = pd.to_datetime(df_pivot["mes"]).dt.strftime(
                            "%Y-%m"
                        )

                        # Juntar com as metas
                        if not df_metas.empty:
                            df_final = pd.merge(
                                df_pivot, df_metas, on="mes", how="left"
                            )
                        else:
                            df_final = df_pivot
                            df_final["meta"] = 0

                        # Preparar para o gráfico em camadas
                        df_melted = df_final.melt(
                            id_vars=["mes", "meta"],
                            value_vars=["Realizado", "Previsto"],
                            var_name="Legenda",
                            value_name="Valor",
                        )

                        # Gráfico de Barras
                        bar_chart = (
                            alt.Chart(df_melted)
                            .mark_bar()
                            .encode(
                                x=alt.X("mes:N", sort=None, title="Mês"),
                                y=alt.Y("Valor:Q", title="Valor (R$)"),
                                color=alt.Color(
                                    "Legenda:N",
                                    scale=alt.Scale(
                                        domain=["Realizado", "Previsto"],
                                        range=["#1f77b4", "#aec7e8"],
                                    ),
                                ),
                                tooltip=["mes", "Legenda", "Valor"],
                            )
                        )
                        # Linha da Meta
                        line_chart = (
                            alt.Chart(df_final)
                            .mark_line(color="red", strokeDash=[5, 5], size=3)
                            .encode(
                                x=alt.X("mes:N", sort=None),
                                y=alt.Y("meta:Q", title="Meta"),
                                tooltip=["mes", alt.Tooltip("meta:Q", format="$,.2f")],
                            )
                        )
                        # Sobrepor gráficos
                        final_chart = (bar_chart + line_chart).interactive()
                        st.altair_chart(final_chart, use_container_width=True)

                    # Gráfico 2: Análise de Rentabilidade
                    st.markdown("#### Análise de Rentabilidade por Entrega")
                    df_rentabilidade = pd.DataFrame(
                        [d.model_dump() for d in relatorio.dados_rentabilidade_grafico]
                    )
                    if not df_rentabilidade.empty:
                        # Prepara os dados para o gráfico de barras agrupadas
                        df_melted = df_rentabilidade.melt(
                            id_vars=["rcm_id"],
                            value_vars=["custo_estimado", "custo_realizado"],
                            var_name="Tipo de Custo",
                            value_name="Valor",
                        )
                        chart_rent = (
                            alt.Chart(df_melted)
                            .mark_bar()
                            .encode(
                                x=alt.X("rcm_id:N", title="ID da RCM"),
                                y=alt.Y("Valor:Q", title="Custo (R$)"),
                                color="Tipo de Custo:N",
                                xOffset="Tipo de Custo:N",
                                tooltip=["rcm_id", "Tipo de Custo", "Valor"],
                            )
                        )
                        st.altair_chart(chart_rent, use_container_width=True)

                    status.update(label="Gerando análise textual...")
                    st.markdown("#### Análise e Insights")
                    st.info(f"**Insights:**\n{relatorio.insights_historico}")
                    st.success(f"**Previsão:**\n{relatorio.analise_preditiva}")
                else:
                    st.markdown("#### Análise do Agente")
                    # Exibe as mensagens de ajuda que o agente agora fornece
                    st.warning(relatorio.insights_historico)
                    st.info(relatorio.analise_preditiva)

            except Exception as e:
                st.error(f"Erro ao gerar relatório de faturamento: {e}")

    st.markdown("---")
    st.markdown("### Agente de Documentação")
    st.write(
        "Monitora RCMs concluídos e propõe atualizações para os manuais do sistema, mantendo a documentação sempre atualizada."  # noqa: E501
    )
    if st.button("Executar Ciclo do Agente de Documentação"):
        with st.status(
            "🧠 O Agente de Documentação está pensando...", expanded=True
        ) as status:
            try:
                agente_documentacao = AgenteDocumentacao()
                relatorio = agente_documentacao.executar_ciclo_atualizacao(
                    status_callback=lambda msg: status.update(label=f"🧠 {msg}")
                )
                st.markdown(relatorio)
            except Exception as e:  # noqa: BLE001
                st.error(
                    f"Ocorreu um erro durante a execução do Agente de Documentação: {e}"
                )


def render_documentation_generator_interface() -> None:
    """Renderiza a interface para o gerador de documentação."""
    st.subheader("📚 Gerador de Documentação")
    st.write(
        "Solicite um manual sobre qualquer funcionalidade do sistema. O agente irá compilar as informações e apresentá-las em um formato organizado."  # noqa: E501
    )

    agente_doc = load_agente_documentacao()

    topico = st.text_input(
        "Sobre qual tópico você gostaria de gerar um manual?",
        placeholder="Ex: Férias, Consignação, Horas Extras",
    )

    if st.button("Gerar Manual"):
        if not topico:
            st.warning("Por favor, insira um tópico.")
        else:
            with st.spinner(
                f"O Agente de Documentação está compilando o manual sobre '{topico}'..."
            ):
                manual_markdown = agente_doc.gerar_manual_por_topico(topico)
                st.markdown(manual_markdown)


def render_chatbot_page() -> None:
    """Renderiza a página combinada de Chatbot e Análise."""
    st.header("💬 Chatbot & Análise de Solicitações")

    tab1, tab2, tab3 = st.tabs(
        ["Chat Conversacional", "Análise de Solicitação", "Dashboard BI"]
    )

    with tab1:
        render_chat_interface()

    with tab2:
        render_analysis_interface()

    with tab3:
        render_dashboard_interface()


def render_rcm_planning_page() -> None:
    """Renderiza a página de Planejamento de RCM (focada no agente de planejamento)."""
    st.header("📋 Planejamento de RCM")
    st.write(
        "Área dedicada à geração e aprovação de Relatórios de Controle de Mudança."
    )

    # Reutiliza a interface de análise, mas focada em gerar o plano
    # Na verdade, a interface de análise já tem o botão de gerar plano.
    # Podemos apenas renderizar a interface de análise aqui também, ou criar uma específica.
    # Para simplificar, vamos renderizar a interface de análise, pois o fluxo começa lá.
    render_analysis_interface()


def render_management_page() -> None:
    """Renderiza a página de Gestão e Qualidade (Agentes Proativos)."""
    st.header("⚙️ Gestão & Qualidade")
    render_proactive_agents_interface()


def render_documentation_page() -> None:
    """Renderiza a página de Documentação."""
    st.header("📚 Gerador de Documentação")

    tab1, tab2 = st.tabs(["Gerador de Manuais", "Atualizações Pendentes"])

    with tab1:
        render_documentation_generator_interface()

    with tab2:
        st.subheader("📝 Atualizações de Documentação Pendentes")
        st.write("Revise e aprove as sugestões de atualização geradas pelo agente.")

        agente_doc = load_agente_documentacao()
        pendentes = agente_doc.listar_atualizacoes_pendentes()

        if not pendentes:
            st.info("✅ Nenhuma atualização pendente no momento.")
        else:
            for item in pendentes:
                with st.expander(f"RCM: {item['rcm_titulo']} (ID: {item['rcm_id']})"):
                    st.markdown(f"**Resumo da Mudança:** {item['resumo']}")
                    st.markdown("**Texto Sugerido:**")
                    st.code(item["texto_novo"], language="markdown")

                    if st.button(
                        "✅ Aprovar Atualização", key=f"btn_approve_{item['id']}"
                    ):
                        try:
                            if agente_doc.aprovar_atualizacao(item["id"]):
                                st.success("Atualização aprovada com sucesso!")
                                st.rerun()
                            else:
                                st.error("Erro ao aprovar atualização.")
                        except Exception as e:
                            st.error(f"Erro: {e}")


def main() -> None:
    """Função principal da aplicação Streamlit."""
    load_dotenv()
    carregar_dados_faturamento()  # Garante que os dados de faturamento estão no banco

    # Inicializa o grafo e a ingestão de dados (se necessário)
    initialize_graph()

    st.set_page_config(
        page_title="RAG SYS-RH - Assistente Inteligente",
        page_icon="🤖",
        layout="wide",
    )

    st.title("🤖 RAG SYS-RH - Assistente Inteligente")

    # Sidebar para navegação
    st.sidebar.title("Navegação")

    # Botão de recarga manual
    if st.sidebar.button("🔄 Recarregar Conhecimento"):
        with st.sidebar.status("Recarregando dados...", expanded=True):
            initialize_graph.clear()  # Limpa o cache da inicialização
            DataIngestion().run_ingestion(clear_db=False)  # Ingestão incremental
            st.success("Conhecimento atualizado!")

    page = st.sidebar.radio(
        "Escolha o módulo:",
        (
            "Chatbot & Análise",
            "Planejamento de RCM",
            "Gestão & Qualidade",
            "Gerador de Documentação",
        ),
    )

    if page == "Chatbot & Análise":
        render_chatbot_page()
    elif page == "Planejamento de RCM":
        render_rcm_planning_page()
    elif page == "Gestão & Qualidade":
        render_management_page()
    elif page == "Gerador de Documentação":
        render_documentation_page()


if __name__ == "__main__":
    main()

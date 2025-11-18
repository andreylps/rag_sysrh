import logging
import os
from io import StringIO
from typing import Any

import altair as alt
import pandas as pd
import streamlit as st
from dotenv import load_dotenv
from langchain_core.tools import Tool
from langchain_neo4j import Neo4jGraph
from langchain_openai import ChatOpenAI

from rag_sysrh.agent_executor import build_agent
from rag_sysrh.agente_documentacao import AgenteDocumentacao
from rag_sysrh.agente_faturamento import AgenteFaturamento
from rag_sysrh.agente_qualidade import AgenteQualidade
from rag_sysrh.analista_workflow import AnalistaWorkflow
from rag_sysrh.main import get_tools

# Configura o logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


# --- FUNÇÕES DE CACHE PARA PERFORMANCE ---
@st.cache_resource
def load_tools() -> list[Tool]:
    """Carrega as ferramentas do agente e as armazena em cache."""
    return get_tools()


@st.cache_resource
def load_analista_workflow(_tools: list[Tool]) -> AnalistaWorkflow:
    """Carrega o workflow de análise e o armazena em cache."""
    return AnalistaWorkflow(tools=_tools)


@st.cache_resource
def load_agente_documentacao() -> AgenteDocumentacao:
    """Carrega o agente de documentação e o armazena em cache."""
    return AgenteDocumentacao()


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
    tools = load_tools()
    workflow = load_analista_workflow(tools)

    solicitacao_texto = st.text_area("Cole o texto da solicitação aqui:", height=150)

    if st.button("Analisar Solicitação"):
        if not solicitacao_texto:
            st.warning("Por favor, insira o texto da solicitação.")
        else:
            with st.spinner(
                "Executando workflow de análise... Isso pode levar um minuto."
            ):
                try:
                    relatorio = workflow.run(solicitacao_texto)

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

                except Exception as e:  # noqa: BLE001
                    st.error(f"Ocorreu um erro durante a análise: {e}")


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
                    status.update(label="Renderizando gráficos...")
                    st.markdown("#### Gráfico Comparativo de Faturamento")
                    df_predicao = pd.DataFrame(
                        [d.model_dump() for d in relatorio.dados_predicao_grafico]
                    )
                    if not df_predicao.empty:
                        df_predicao["mes"] = pd.to_datetime(
                            df_predicao["mes"]
                        ).dt.strftime("%Y-%m")
                        chart = (
                            alt.Chart(df_predicao)
                            .mark_bar()
                            .encode(
                                x=alt.X(
                                    "mes:N", title="Mês", sort=alt.SortField("mes")
                                ),
                                y=alt.Y("valor:Q", title="Valor (R$)"),
                                color=alt.Color(
                                    "tipo:N",
                                    title="Tipo",
                                    scale=alt.Scale(
                                        domain=["Realizado", "Previsto"],
                                        range=["#4c78a8", "#f58518"],
                                    ),
                                ),
                                tooltip=["mes:N", "valor:Q"],
                            )
                        )
                        st.altair_chart(chart, use_container_width=True)

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
                    st.warning("Não foram encontrados dados suficientes.")
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


def main() -> None:
    """Função principal da aplicação Streamlit."""
    load_dotenv()
    carregar_dados_faturamento()  # Garante que os dados de faturamento estão no banco
    st.set_page_config(page_title="Assistente SYSRH", layout="wide")
    st.title("🤖 Assistente de Conhecimento SYSRH")

    st.sidebar.title("Modos de Operação")
    modo = st.sidebar.radio(
        "Escolha a ferramenta:",
        (
            "Consulta Conversacional",
            "Análise de Solicitação",
            "Dashboard de BI",
            "Agentes Proativos",
            "Gerador de Documentação",
        ),
    )

    if modo == "Consulta Conversacional":
        render_chat_interface()
    elif modo == "Análise de Solicitação":
        render_analysis_interface()
    elif modo == "Dashboard de BI":
        render_dashboard_interface()
    elif modo == "Agentes Proativos":
        render_proactive_agents_interface()
    elif modo == "Gerador de Documentação":
        render_documentation_generator_interface()


if __name__ == "__main__":
    main()

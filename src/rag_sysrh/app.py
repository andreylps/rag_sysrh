import logging
import os

import altair as alt
import pandas as pd
import streamlit as st
from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph
from langchain_openai import ChatOpenAI

from rag_sysrh.agent_executor import build_agent
from rag_sysrh.analista_workflow import AnalistaWorkflow
from rag_sysrh.main import get_tools

# Configura o logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


def render_chat_interface() -> None:
    """Renderiza a interface do chat conversacional."""
    st.subheader("💬 Chat Conversacional")
    st.write(
        "Faça perguntas sobre manuais, regras de negócio, solicitações ou clientes."
    )

    # Inicializa o agente e o histórico no estado da sessão
    if "agent_executor" not in st.session_state:
        tools = get_tools()
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

    if "analista_workflow" not in st.session_state:
        # Passa as ferramentas já carregadas para o workflow
        tools = get_tools()
        st.session_state.analista_workflow = AnalistaWorkflow(tools)

    solicitacao_texto = st.text_area("Cole o texto da solicitação aqui:", height=150)

    if st.button("Analisar Solicitação"):
        if not solicitacao_texto:
            st.warning("Por favor, insira o texto da solicitação.")
        else:
            with st.spinner(
                "Executando workflow de análise... Isso pode levar um minuto."
            ):
                try:
                    workflow = st.session_state.analista_workflow
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
                st.altair_chart(chart_status, use_container_width=True)

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
                st.altair_chart(chart_responsavel, use_container_width=True)

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


def main() -> None:
    """Função principal da aplicação Streamlit."""
    load_dotenv()
    st.set_page_config(page_title="Assistente SYSRH", layout="wide")
    st.title("🤖 Assistente de Conhecimento SYSRH")

    st.sidebar.title("Modos de Operação")
    modo = st.sidebar.radio(
        "Escolha a ferramenta:",
        ("Consulta Conversacional", "Análise de Solicitação", "Dashboard de BI"),
    )

    if modo == "Consulta Conversacional":
        render_chat_interface()
    elif modo == "Análise de Solicitação":
        render_analysis_interface()
    elif modo == "Dashboard de BI":
        render_dashboard_interface()


if __name__ == "__main__":
    main()

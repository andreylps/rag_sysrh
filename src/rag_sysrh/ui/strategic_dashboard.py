import altair as alt
import pandas as pd
import streamlit as st

from rag_sysrh.agents.strategic_manager import StrategicManagerAgent


def render_strategic_dashboard():
    """Renderiza o Dashboard do Gerente Estratégico."""
    st.title("📈 Gerente Estratégico SYSRH (BI & Insights)")
    st.markdown("Monitoramento proativo da saúde operacional e financeira.")

    # Inicializa o Agente
    agent = StrategicManagerAgent()

    # --- Sidebar de Filtros ---
    st.sidebar.header("Filtros de Análise")

    periodo = st.sidebar.selectbox(
        "Período de Análise",
        ["30d", "current_month", "90d"],
        format_func=lambda x: "Últimos 30 Dias"
        if x == "30d"
        else ("Mês Atual" if x == "current_month" else "Últimos 90 Dias"),
    )

    # Mock de listas para filtros (idealmente viria do DataService)
    times = ["Todos", "FUNC", "FOLHA", "PAGTO", "PREV", "SERV", "INFOB", "SUST"]
    clientes = ["Todos", "ALESC", "SC", "FAB", "Roraima"]

    time_sel = st.sidebar.selectbox("Time", times)
    cliente_sel = st.sidebar.selectbox("Cliente", clientes)

    if st.sidebar.button("🔍 Executar Análise Estratégica"):
        with st.spinner("🤖 O Gerente Estratégico está analisando os dados..."):
            # Executa a análise
            resultado = agent.run_analysis(periodo, time_sel, cliente_sel)
            st.session_state.strategic_result = resultado

    # --- Renderização dos Resultados ---
    if "strategic_result" in st.session_state:
        res = st.session_state.strategic_result
        data = res["data"]
        analise = res["analysis"]

        # 1. Scorecards (KPIs Principais)
        kpis = data["scan"]["kpis"]
        col1, col2, col3, col4 = st.columns(4)
        col1.metric(
            "Taxa de Entrega",
            f"{kpis['taxa_entrega']}%",
            delta_color="normal" if kpis["taxa_entrega"] > 70 else "inverse",
        )
        col2.metric("Total Entregue", kpis["entregues"])
        col3.metric(
            "Lead Time Médio", f"{kpis['lead_time_medio']} dias", delta_color="inverse"
        )

        if data["financials"]:
            fin = data["financials"]
            col4.metric("Faturamento Est.", f"R$ {fin['faturamento_realizado']:,.2f}")
        else:
            col4.metric("Demandas Totais", kpis["total_demandas"])

        st.markdown("---")

        # 2. Narrativa Estratégica (O Cérebro do Agente)
        st.subheader("🧠 Análise Estratégica & Recomendações")

        with st.container(border=True):
            st.error(f"🚨 **ALERTA:** {analise.alerta_risco}")

            c1, c2 = st.columns(2)
            with c1:
                st.markdown("**Evidência (Causa Raiz):**")
                st.info(analise.evidencia_dados)
            with c2:
                st.markdown("**Predição de Risco:**")
                st.warning(analise.analise_preditiva)

            st.markdown("**📋 Plano de Ação Recomendado:**")
            st.markdown(analise.plano_acao)

        st.markdown("---")

        # 3. Visualizações Gráficas
        st.subheader("📊 Indicadores Visuais")

        tab1, tab2, tab3 = st.tabs(["Gargalos", "Atrito/Recusas", "Eficiência"])

        with tab1:
            st.markdown("#### Tempo Médio por Etapa (Gargalos)")
            if data["bottlenecks"]:
                df_bottle = pd.DataFrame(data["bottlenecks"])
                chart_bottle = (
                    alt.Chart(df_bottle)
                    .mark_bar()
                    .encode(
                        x=alt.X("etapa", sort=None),
                        y="tempo_medio_dias",
                        color=alt.Color("etapa", legend=None),
                        tooltip=["etapa", "tempo_medio_dias"],
                    )
                    .properties(height=300)
                )
                st.altair_chart(chart_bottle, use_container_width=True)
            else:
                st.info("Sem dados de gargalo para o filtro.")

        with tab2:
            st.markdown("#### Motivos de Recusa/Cancelamento")
            if data["rejections"]:
                df_rej = pd.DataFrame(data["rejections"])
                chart_rej = (
                    alt.Chart(df_rej)
                    .mark_arc(innerRadius=50)
                    .encode(
                        theta=alt.Theta("quantidade", stack=True),
                        color=alt.Color("motivo"),
                        tooltip=["motivo", "quantidade"],
                    )
                )
                st.altair_chart(chart_rej, use_container_width=True)
            else:
                st.info("Nenhuma recusa registrada no período.")

        with tab3:
            st.markdown("#### Eficiência por Time/Cliente (Heatmap)")
            if data["scan"]["heatmap_data"]:
                df_heat = pd.DataFrame(data["scan"]["heatmap_data"])
                chart_heat = (
                    alt.Chart(df_heat)
                    .mark_rect()
                    .encode(
                        x="cliente_extraido:N",
                        y="time_extraido:N",
                        color=alt.Color(
                            "eficiencia:Q", scale=alt.Scale(scheme="redyellowgreen")
                        ),
                        tooltip=[
                            "time_extraido",
                            "cliente_extraido",
                            "eficiencia",
                            "entregues",
                            "total",
                        ],
                    )
                )
                st.altair_chart(chart_heat, use_container_width=True)
            else:
                st.info("Sem dados suficientes para heatmap.")
    else:
        st.info(
            "👈 Selecione os filtros na barra lateral e clique em 'Executar Análise' para iniciar."
        )

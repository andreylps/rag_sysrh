import logging
import os
from io import StringIO

import altair as alt
import pandas as pd
import streamlit as st
from dotenv import load_dotenv
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
def load_tools():  # noqa: ANN201
    """Carrega as ferramentas do agente e as armazena em cache."""
    return get_tools()


@st.cache_resource
def load_analista_workflow(_tools):  # noqa: ANN001, ANN201
    """Carrega o workflow de análise e o armazena em cache."""
    return AnalistaWorkflow(tools=_tools)


@st.cache_resource
def load_agente_documentacao():  # noqa: ANN201
    """Carrega o agente de documentação e o armazena em cache."""
    return AgenteDocumentacao()


@st.cache_resource
def get_logger_stream():  # noqa: ANN201
    """Cria um stream de log para capturar a saída dos agentes."""
    # Usamos um objeto StringIO para capturar os logs em memória
    return StringIO()


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


def render_proactive_agents_interface() -> None:
    """Renderiza a interface para execução manual dos agentes proativos."""
    st.subheader("⚙️ Execução de Agentes Proativos")
    st.write(
        "Dispare manualmente os ciclos de análise dos agentes autônomos do sistema."
    )

    log_stream = get_logger_stream()
    # Limpa o stream antes de cada execução para não acumular logs de execuções passadas
    log_stream.truncate(0)
    log_stream.seek(0)

    # Configura o logger para escrever no stream
    stream_handler = logging.StreamHandler(log_stream)
    stream_handler.setFormatter(
        logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
    )
    # Adiciona o handler ao logger raiz
    logging.getLogger().addHandler(stream_handler)

    st.markdown("---")
    st.markdown("### Agente de Qualidade")
    st.write(
        "Monitora o ciclo de vida das solicitações, validando a qualidade da descrição, conformidade de RCMs, prazos e entregas."  # noqa: E501
    )
    if st.button("Executar Ciclo do Agente de Qualidade"):
        with st.spinner(
            "O Agente de Qualidade está em execução... Isso pode levar alguns minutos."
        ):
            try:
                agente_qualidade = AgenteQualidade()
                resultado = agente_qualidade.executar_ciclo()
                if resultado:
                    st.info(resultado)
                else:
                    st.success("Ciclo do Agente de Qualidade concluído com sucesso!")
                    st.code(log_stream.getvalue(), language="log")
            except Exception as e:  # noqa: BLE001
                st.error(
                    f"Ocorreu um erro durante a execução do Agente de Qualidade: {e}"
                )
                st.code(log_stream.getvalue(), language="log")

    st.markdown("---")
    st.markdown("### Agente de Faturamento")
    st.write(
        "Analisa a rentabilidade das entregas concluídas, comparando o custo estimado com o custo realizado."  # noqa: E501
    )
    if st.button("Executar Ciclo do Agente de Faturamento"):
        with st.spinner("O Agente de Faturamento está em execução..."):
            try:
                agente_faturamento = AgenteFaturamento()
                resultado = agente_faturamento.executar_ciclo()
                if resultado:
                    st.info(resultado)
                else:
                    st.success("Ciclo do Agente de Faturamento concluído com sucesso!")
                    st.code(log_stream.getvalue(), language="log")
            except Exception as e:  # noqa: BLE001
                st.error(
                    f"Ocorreu um erro durante a execução do Agente de Faturamento: {e}"
                )
                st.code(log_stream.getvalue(), language="log")

    st.markdown("---")
    st.markdown("### Agente de Documentação")
    st.write(
        "Monitora RCMs concluídos e propõe atualizações para os manuais do sistema, mantendo a documentação sempre atualizada."  # noqa: E501
    )
    if st.button("Executar Ciclo do Agente de Documentação"):
        with st.spinner("O Agente de Documentação está em execução..."):
            try:
                agente_documentacao = AgenteDocumentacao()
                resultado = agente_documentacao.executar_ciclo_atualizacao()
                if resultado:
                    st.info(resultado)
                else:
                    st.success("Ciclo do Agente de Documentação concluído com sucesso!")
                    st.code(log_stream.getvalue(), language="log")
            except Exception as e:  # noqa: BLE001
                st.error(
                    f"Ocorreu um erro durante a execução do Agente de Documentação: {e}"
                )
                st.code(log_stream.getvalue(), language="log")

    # Remove o handler para não interferir com outros loggers
    logging.getLogger().removeHandler(stream_handler)


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

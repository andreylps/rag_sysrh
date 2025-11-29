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

from langgraph.checkpoint.memory import MemorySaver  # noqa: E402

from rag_sysrh.agent_executor import build_agent  # noqa: E402
from rag_sysrh.agente_bi import AgenteBI  # noqa: E402
from rag_sysrh.agente_documentacao import AgenteDocumentacao  # noqa: E402
from rag_sysrh.agente_faturamento import AgenteFaturamento  # noqa: E402
from rag_sysrh.agente_planejamento_rcm import AgentePlanejamentoRCM  # noqa: E402
from rag_sysrh.agente_qualidade import AgenteQualidade  # noqa: E402
from rag_sysrh.data_ingestion import DataIngestion  # noqa: E402
from rag_sysrh.engine.workflow import SISPWorkflow  # noqa: E402
from rag_sysrh.guarded_workflow import guarded_app  # noqa: E402
from rag_sysrh.main import get_tools  # noqa: E402
from rag_sysrh.ui.strategic_dashboard import render_strategic_dashboard  # noqa: E402

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
            # Check environment variable for automatic ingestion
            enable_ingestion = (
                os.getenv("ENABLE_AUTOMATIC_INGESTION", "false").lower() == "true"
            )

            if enable_ingestion:
                logging.info(
                    "🔄 ENABLE_AUTOMATIC_INGESTION=true. Iniciando processo de ingestão pesada..."
                )
                ingestion = DataIngestion(
                    data_directory="data",
                    structured_data_path="data/solicitacoes.csv",
                    rcm_data_path="data/rcms_01.csv",
                    # Ajuste conforme necessário ou deixe None para processar todos
                    single_manual_path=None,
                )
                ingestion.run_ingestion(clear_db=True)
                logging.info("✅ Ingestão automática concluída.")
            else:
                logging.warning(
                    "⏸️ ENABLE_AUTOMATIC_INGESTION está 'false' ou não definido. Pulando ingestão automática para economizar créditos."
                )
                logging.info(
                    "O sistema iniciará com a base de conhecimento no estado atual do banco de dados."
                )
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
                        # Persiste o plano no estado da sessão para sobreviver ao rerun
                        st.session_state.plano_rcm_atual = plano_rcm

                        # Salva o plano como nó no Neo4j (Status: Pendente Aprovação)
                        # Isso garante que o nó exista quando formos aprovar
                        rcm_node_id = agente_planejamento.salvar_plano_rcm(
                            plano_rcm, relatorio.solicitacao_id
                        )
                        st.session_state.plano_rcm_node_id = rcm_node_id
                        st.toast("✅ Rascunho da RCM salvo no banco de dados!")

                except Exception as e:
                    st.error(f"Erro ao gerar plano de RCM: {e}")

        # Verifica se há um plano gerado no estado (seja agora ou de antes)
        if st.session_state.get("plano_rcm_atual"):
            plano_rcm = st.session_state.plano_rcm_atual

            # Recarrega o agente se necessário (pois ele não é persistido no session_state)
            agente_planejamento = load_agente_planejamento_rcm()

            # FORÇA BRUTA: Garante que o plano exibido esteja limpo, mesmo que venha de um estado antigo
            plano_rcm = agente_planejamento._limpar_html_plano(plano_rcm)
            st.session_state.plano_rcm_atual = (
                plano_rcm  # Atualiza o estado com a versão limpa
            )

            st.markdown("### Plano de RCM Gerado")
            st.markdown(agente_planejamento.formatar_plano_para_markdown(plano_rcm))
            # --- Fluxo de Aprovação (Human-in-the-Loop) ---
            st.warning(
                "⚠️ Este plano está como 'Pendente Aprovação'. Revise antes de aprovar."
            )

            col1, col2 = st.columns(2)
            with col1:
                if st.button("✅ Aprovar Plano de RCM"):
                    with st.spinner("Oficializando RCM..."):
                        try:
                            # Usa o ID do nó salvo anteriormente para aprovar
                            node_id = st.session_state.get("plano_rcm_node_id")
                            if not node_id:
                                # Fallback: tenta salvar agora se não tiver ID (caso de estado antigo)
                                node_id = agente_planejamento.salvar_plano_rcm(
                                    plano_rcm, relatorio.solicitacao_id
                                )
                                st.session_state.plano_rcm_node_id = node_id

                            rcm_id = agente_planejamento.aprovar_plano_rcm(node_id)

                            if rcm_id:
                                st.success(
                                    f"RCM '{plano_rcm.titulo_rcm}' aprovada e oficializada!"
                                )

                                st.balloons()
                                st.session_state.rcm_aprovada_id = rcm_id
                                st.session_state.rcm_aprovada_titulo = (
                                    plano_rcm.titulo_rcm
                                )
                                # Força um rerun para atualizar a interface e mostrar o botão de exportar fora do bloco
                                st.rerun()
                            else:
                                st.error("Não foi possível aprovar a RCM.")
                        except Exception as e:
                            st.error(f"Erro ao aprovar RCM: {e}")
            with col2:
                if st.button("❌ Descartar Rascunho", key="btn_discard_draft"):
                    st.info(
                        "Rascunho descartado (funcionalidade de exclusão a implementar)."
                    )

            # Se a RCM acabou de ser aprovada (ou já estava no estado), mostra o botão de exportar
            if st.session_state.get("rcm_aprovada_titulo") == plano_rcm.titulo_rcm:
                st.markdown("---")
                st.success("✅ RCM Aprovada! Pronta para integração.")
                if st.button("📤 Exportar para GitHub (Real)", key="btn_export_final"):
                    with st.spinner("Exportando issue para o GitHub..."):
                        try:
                            # Usa o conector real do GitHub
                            from rag_sysrh.github_connector import GitHubConnector

                            # Verifica se o token está configurado
                            if not os.getenv("GITHUB_TOKEN"):
                                st.error("GITHUB_TOKEN não configurado no arquivo .env")
                            else:
                                connector = GitHubConnector()
                                ext_id = agente_planejamento.exportar_para_externo(
                                    st.session_state.rcm_aprovada_id,
                                    connector,
                                )
                                if ext_id:
                                    st.success(
                                        f"Issue criada com sucesso no GitHub! [Acessar Issue]({ext_id})"
                                    )
                                    st.balloons()
                                else:
                                    st.error("Falha ao exportar RCM.")
                        except Exception as e:
                            st.error(f"Erro na exportação: {e}")


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

    # --- FILTROS ---
    with st.expander("🔍 Filtros de Visualização", expanded=False):
        col_f1, col_f2 = st.columns(2)
        with col_f1:
            # Filtro de Status
            all_statuses = graph.query(
                "MATCH (s:Solicitacao) RETURN DISTINCT s.status as status"
            )
            status_options = [r["status"] for r in all_statuses] if all_statuses else []
            selected_statuses = st.multiselect(
                "Filtrar por Status", status_options, default=status_options
            )

        with col_f2:
            # Filtro de Responsável
            all_resps = graph.query(
                "MATCH (r:Responsavel) RETURN DISTINCT r.nome as nome"
            )
            resp_options = [r["nome"] for r in all_resps] if all_resps else []
            selected_resps = st.multiselect(
                "Filtrar por Responsável", resp_options, default=resp_options
            )

    # Construção da Query Base com Filtros
    where_clauses = []
    params = {}

    if selected_statuses:
        where_clauses.append("s.status IN $statuses")
        params["statuses"] = selected_statuses

    if selected_resps:
        where_clauses.append(
            "exists((s)-[:ATRIBUIDA_A]->(:Responsavel {nome: $resp_name}))"
        )
        # Nota: Multiselect para responsável exigiria uma query mais complexa se quisermos filtrar "qualquer um dos selecionados".
        # Simplificação: Filtrar onde o responsável ESTÁ na lista selecionada.
        # Ajuste da query acima para lista:
        where_clauses.pop()  # Remove a anterior
        where_clauses.append(
            "EXISTS { MATCH (s)-[:ATRIBUIDA_A]->(r:Responsavel) WHERE r.nome IN $resps }"
        )
        params["resps"] = selected_resps

    where_stmt = " WHERE " + " AND ".join(where_clauses) if where_clauses else ""

    # --- KPIS ---
    st.markdown("### Indicadores Chave (KPIs)")
    kpi_col1, kpi_col2, kpi_col3, kpi_col4 = st.columns(4)

    # Total Solicitações
    total_query = f"MATCH (s:Solicitacao){where_stmt} RETURN count(s) as total"
    total_res = graph.query(total_query, params=params)
    total_val = total_res[0]["total"] if total_res else 0
    kpi_col1.metric("Total Solicitações", total_val)

    # Em Aberto (Status != Concluída e != Cancelada)
    # Ajuste conforme seus status reais. Assumindo 'Concluída' como final.
    open_query = f"MATCH (s:Solicitacao){where_stmt} AND NOT s.status IN ['Concluída', 'Cancelada'] RETURN count(s) as total"
    # Se o where_stmt já existir, precisamos usar AND. Se não, WHERE.
    # Pequeno fix para concatenação correta:
    if where_stmt:
        open_query = f"MATCH (s:Solicitacao){where_stmt} AND NOT s.status IN ['Concluída', 'Cancelada'] RETURN count(s) as total"
    else:
        open_query = "MATCH (s:Solicitacao) WHERE NOT s.status IN ['Concluída', 'Cancelada'] RETURN count(s) as total"

    open_res = graph.query(open_query, params=params)
    open_val = open_res[0]["total"] if open_res else 0
    kpi_col2.metric("Em Aberto", open_val)

    # Concluídas
    done_query = f"MATCH (s:Solicitacao){where_stmt} AND s.status = 'Concluída' RETURN count(s) as total"
    if not where_stmt:
        done_query = "MATCH (s:Solicitacao) WHERE s.status = 'Concluída' RETURN count(s) as total"

    done_res = graph.query(done_query, params=params)
    done_val = done_res[0]["total"] if done_res else 0
    kpi_col3.metric("Concluídas", done_val)

    # RCMs Aprovadas (Métrica de Negócio)
    rcm_query = "MATCH (r:RCM) RETURN count(r) as total"
    # RCMs podem não estar ligadas diretamente aos filtros de solicitação da mesma forma,
    # mas vamos manter global ou tentar filtrar se houver relação.
    # Simplificação: Global.
    rcm_res = graph.query(rcm_query)
    rcm_val = rcm_res[0]["total"] if rcm_res else 0
    kpi_col4.metric("RCMs Aprovadas", rcm_val)

    st.markdown("---")

    # --- GERAÇÃO DOS GRÁFICOS ---
    col1, col2 = st.columns(2)

    with col1:
        st.markdown("#### Distribuição por Status")
        with st.spinner("Carregando dados..."):
            status_query = f"MATCH (s:Solicitacao){where_stmt} RETURN s.status AS status, count(s) AS quantidade"
            status_data = graph.query(status_query, params=params)

            if status_data:
                df_status = pd.DataFrame(status_data)
                chart_status = (
                    alt.Chart(df_status)
                    .mark_bar()
                    .encode(
                        x=alt.X("quantidade:Q", title="Quantidade"),
                        y=alt.Y("status:N", title="Status", sort="-x"),
                        color=alt.Color("status:N", legend=None),
                        tooltip=["status", "quantidade"],
                    )
                    .interactive()
                )
                st.altair_chart(chart_status, use_container_width=True)
            else:
                st.info("Sem dados para exibir com os filtros atuais.")

    with col2:
        st.markdown("#### Carga por Responsável")
        with st.spinner("Carregando dados..."):
            # Query ajustada para usar os filtros na Solicitação 's'
            resp_query = f"""
                MATCH (s:Solicitacao)-[:ATRIBUIDA_A]->(r:Responsavel)
                {where_stmt}
                RETURN r.nome AS responsavel, count(s) AS quantidade
                ORDER BY quantidade DESC LIMIT 10
            """
            responsavel_data = graph.query(resp_query, params=params)

            if responsavel_data:
                df_responsavel = pd.DataFrame(responsavel_data)
                chart_responsavel = (
                    alt.Chart(df_responsavel)
                    .mark_bar()
                    .encode(
                        x=alt.X("quantidade:Q", title="Quantidade"),
                        y=alt.Y("responsavel:N", title="Responsável", sort="-x"),
                        color=alt.Color("responsavel:N", legend=None),
                        tooltip=["responsavel", "quantidade"],
                    )
                    .interactive()
                )
                st.altair_chart(chart_responsavel, use_container_width=True)
            else:
                st.info("Sem dados para exibir com os filtros atuais.")

    # --- GRÁFICO TEMPORAL (NOVO) ---
    st.markdown("#### Evolução Temporal (Solicitações Criadas)")
    # Assumindo que existe uma propriedade de data. Se não existir, vamos usar um mock ou tentar extrair do ID/Log.
    # O grafo atual pode não ter data_criacao explícita em todas as s:Solicitacao.
    # Vamos verificar se conseguimos simular ou se usamos o que tem.
    # Fallback: Se não tiver data, mostramos aviso.

    # Tentativa de buscar data. Se não tiver, o gráfico ficará vazio.
    # Melhoria: Garantir que na ingestão a data seja setada.
    # Por enquanto, vamos tentar agrupar por 'data_criacao' se existir.

    time_query = f"""
        MATCH (s:Solicitacao)
        {where_stmt}
        WHERE s.data_criacao IS NOT NULL
        RETURN date(datetime(s.data_criacao)) as data, count(s) as quantidade
        ORDER BY data
    """
    # Nota: Se data_criacao for string ISO, datetime() converte.

    try:
        time_data = graph.query(time_query, params=params)
        if time_data:
            df_time = pd.DataFrame(time_data)
            # Converter objeto neo4j date para string ou datetime python
            df_time["data"] = df_time["data"].astype(str)

            chart_time = (
                alt.Chart(df_time)
                .mark_line(point=True)
                .encode(
                    x=alt.X("data:T", title="Data"),
                    y=alt.Y("quantidade:Q", title="Solicitações"),
                    tooltip=["data", "quantidade"],
                )
                .interactive()
            )
            st.altair_chart(chart_time, use_container_width=True)
        else:
            st.warning(
                "Não foi possível gerar o gráfico temporal (propriedade 'data_criacao' ausente ou filtros muito restritivos)."
            )
    except Exception:
        st.warning("Dados temporais indisponíveis para visualização.")

    # --- CHAT COM OS DADOS (AGENTE BI) ---
    st.markdown("---")
    st.markdown("### 💬 Chat com os Dados")
    with st.expander("Conversar com o Agente de Dados", expanded=True):
        st.write(
            "Faça perguntas em linguagem natural sobre os dados do sistema (ex: 'Quantas solicitações estão atrasadas?')."
        )

        # Inicializa o histórico de chat do BI se não existir
        if "bi_messages" not in st.session_state:
            st.session_state.bi_messages = []

        # Exibe histórico
        for msg in st.session_state.bi_messages:
            with st.chat_message(msg["role"]):
                st.markdown(msg["content"])
                if "cypher" in msg:
                    with st.expander("Ver Query Cypher"):
                        st.code(msg["cypher"], language="cypher")

        # Input do usuário
        if prompt := st.chat_input("Pergunte aos dados...", key="bi_chat_input"):
            # Adiciona pergunta ao histórico
            st.session_state.bi_messages.append({"role": "user", "content": prompt})
            with st.chat_message("user"):
                st.markdown(prompt)

            # Processa resposta
            with st.chat_message("assistant"):
                with st.spinner("Analisando dados..."):
                    try:
                        # Instancia o agente sob demanda (poderia ser cacheado)
                        agente_bi = AgenteBI()
                        resultado = agente_bi.responder_pergunta(prompt)

                        resposta_texto = resultado["resposta"]
                        cypher_query = resultado["cypher"]

                        st.markdown(resposta_texto)
                        with st.expander("Ver Query Cypher Gerada"):
                            st.code(cypher_query, language="cypher")

                        # Salva no histórico
                        st.session_state.bi_messages.append(
                            {
                                "role": "assistant",
                                "content": resposta_texto,
                                "cypher": cypher_query,
                            }
                        )
                    except Exception as e:
                        st.error(f"Erro ao processar pergunta: {e}")

    # --- AGENTE ANALISTA DE BI (Resumo Estático) ---
    st.markdown("---")
    st.markdown("### 🧠 Análise Estática (Resumo)")
    if st.button("Gerar Análise dos Gráficos"):
        with st.spinner("O agente de BI está analisando os gráficos..."):
            llm = ChatOpenAI(model="gpt-4-turbo", temperature=0)
            prompt = f"""Você é um analista de Business Intelligence. Sua tarefa é analisar os dados brutos dos gráficos e fornecer um resumo com pontos de atenção e sugestões.
            
            Dados de Distribuição por Status:
            {status_data if "status_data" in locals() else "N/A"}

            Dados de Carga de Trabalho por Responsável:
            {responsavel_data if "responsavel_data" in locals() else "N/A"}

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
                # ingestion = DataIngestion(
                #     neo4j_uri=os.getenv("NEO4J_URI", "bolt://localhost:7687"),
                #     neo4j_user=os.getenv("NEO4J_USER", "neo4j"),
                #     neo4j_password=os.getenv("NEO4J_PASSWORD", "password"),
                # )
                # ingestion.run_ingestion(clear_db=True)
                # logging.info("Ingestão automática concluída.") e a atualiza
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
                            .interactive()
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

                    else:
                        st.info("Dados insuficientes para gerar o gráfico.")

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


def render_sisp_interface() -> None:
    """Renderiza a interface de Engenharia de Software SISP (HIL)."""
    st.subheader("🏗️ Engenharia de Software SISP 2.3")
    st.write(
        "Geração de documentação formal e cálculo de métricas com supervisão humana."
    )

    # Inicialização de Estado
    if "sisp_thread_id" not in st.session_state:
        st.session_state.sisp_thread_id = (
            "thread_sisp_1"  # Fixo por enquanto, ideal ser dinâmico
        )
    if "sisp_app" not in st.session_state:
        # Inicializa o workflow com memória
        memory = MemorySaver()
        workflow = SISPWorkflow()

        # Usa o método de construção do próprio workflow, mas injetando o checkpointer
        # Para isso, precisamos que o build_graph aceite checkpointer ou retornamos o builder
        # Como o build_graph atual já compila, vamos adaptar o app.py para usar os métodos restaurados
        # ou melhor, vamos usar o build_graph do workflow se possível, mas ele não aceita checkpointer.
        # Vamos manter a construção manual aqui por enquanto, pois ela permite injetar o memory.

        from langgraph.graph import END, StateGraph

        from rag_sysrh.engine.models import EstadoEngenharia

        builder = StateGraph(EstadoEngenharia)
        builder.add_node("analise_ia", workflow._node_analise_ia)
        builder.add_node("validacao_humana", workflow._node_human_input_check)
        builder.add_node("motor_sisp", workflow._node_calculo_sisp)
        builder.add_node("geracao_docs", workflow._node_geracao_docs)
        builder.add_node(
            "auditoria_qualidade", workflow._node_auditoria_qualidade
        )  # Adicionado Auditoria

        builder.set_entry_point("analise_ia")
        builder.add_edge("analise_ia", "validacao_humana")
        builder.add_edge("validacao_humana", "motor_sisp")
        builder.add_edge("motor_sisp", "geracao_docs")
        builder.add_edge("geracao_docs", "auditoria_qualidade")
        builder.add_edge("auditoria_qualidade", END)

        st.session_state.sisp_app = builder.compile(
            checkpointer=memory, interrupt_before=["validacao_humana"]
        )

    # Input da Solicitação (Pode vir da análise anterior ou novo)
    default_text = ""
    if st.session_state.get("relatorio_analise"):
        # Pré-preenche com resumo se houver
        rel = st.session_state.relatorio_analise
        default_text = f"{rel.resumo_problema}\n\nDiagnóstico: {rel.diagnostico}"

    solicitacao = st.text_area(
        "Descreva a Demanda Técnica:", value=default_text, height=150, key="sisp_input"
    )

    # Botão de Início
    if st.button("🚀 Iniciar Engenharia SISP"):
        if not solicitacao:
            st.warning("Preencha a solicitação.")
        else:
            with st.spinner("🤖 IA Analisando Risco e Identificando Itens..."):
                thread_config = {
                    "configurable": {"thread_id": st.session_state.sisp_thread_id}
                }
                inputs = {"solicitacao_original": solicitacao}

                # Executa até a pausa
                for event in st.session_state.sisp_app.stream(
                    inputs, config=thread_config
                ):
                    pass  # Apenas consome o stream até parar

                st.session_state.sisp_status = "WAITING_INPUT"
                st.rerun()

    # Área de Interação Humana (HIL)
    if st.session_state.get("sisp_status") == "WAITING_INPUT":
        st.info("⏸️ Workflow Pausado: Aguardando Input Humano (Tabela 0)")

        # Recupera estado atual para mostrar o que a IA achou
        thread_config = {"configurable": {"thread_id": st.session_state.sisp_thread_id}}
        state_snapshot = st.session_state.sisp_app.get_state(thread_config)

        if state_snapshot.values.get("itens_identificados"):
            st.write("### 📋 Itens Identificados pela IA")
            itens = state_snapshot.values["itens_identificados"]
            for item in itens:
                st.markdown(
                    f"- **{item.nome}** ({item.tipo.value}): {item.descricao} (DER: {item.der_estimado}, RLR: {item.rlr_estimado})"
                )

        st.markdown("---")
        deflator = st.number_input(
            "Informe o Deflator/Redutor (Tabela 0)",
            min_value=0.0,
            max_value=1.0,
            value=1.0,
            step=0.05,
            help="1.0 = Sem redução (Desenvolvimento Pleno). 0.5 = Manutenção Adaptativa, etc.",
        )

        if st.button("✅ Confirmar e Gerar Documentação"):
            with st.spinner("⚙️ Calculando Métricas e Gerando Arquivos..."):
                # Atualiza estado e retoma
                st.session_state.sisp_app.update_state(
                    thread_config, {"deflator_tabela0": deflator}
                )

                # Resume (passando None pois já atualizamos estado)
                for event in st.session_state.sisp_app.stream(
                    None, config=thread_config
                ):
                    pass

                st.session_state.sisp_status = "COMPLETED"
                st.rerun()

    # Área de Resultados
    if st.session_state.get("sisp_status") == "COMPLETED":
        st.success("✅ Processo de Engenharia Concluído!")

        thread_config = {"configurable": {"thread_id": st.session_state.sisp_thread_id}}
        final_state = st.session_state.sisp_app.get_state(thread_config)
        res = final_state.values.get("resultado_sisp")
        verdict = final_state.values.get("audit_verdict")

        if res and verdict:
            # --- Seção de Auditoria (Quality Gate) ---
            st.markdown("### 🛡️ Auditoria de Qualidade & Compliance")

            if verdict.audit_status == "APROVADO":
                st.success(
                    f"✅ **APROVADO** (Nota Técnica: {verdict.quality_score}/5.0)"
                )
                st.info(f"📝 {verdict.final_comments}")
            else:
                st.error(
                    f"❌ **REPROVADO** (Nota Técnica: {verdict.quality_score}/5.0)"
                )
                st.warning(f"⚠️ {verdict.final_comments}")

            # Exibe Não-Conformidades
            if verdict.non_conformities:
                with st.expander(
                    "Detalhes da Auditoria (Não-Conformidades)", expanded=True
                ):
                    for nc in verdict.non_conformities:
                        severity_icon = (
                            "🔴"
                            if nc.severity == "CRITICAL"
                            else ("🟠" if nc.severity == "HIGH" else "🟡")
                        )
                        st.markdown(f"{severity_icon} **[{nc.type}]** {nc.description}")

            st.markdown("---")

            # --- Resultados e Downloads (Apenas se Aprovado) ---
            if verdict.audit_status == "APROVADO":
                col1, col2, col3 = st.columns(3)
                col1.metric("PF Bruto", res.pf_bruto_total)
                col2.metric("PF Líquido", f"{res.pf_liquido_total:.2f}")
                col3.metric("Prazo Estimado", f"{res.prazo_estimado_dias} dias")

                st.markdown("### 📂 Documentação Gerada")

                # Botões de Download
                if os.path.exists(res.memoria_calculo_path):
                    with open(res.memoria_calculo_path, "rb") as f:
                        st.download_button(
                            "📥 Baixar Memória de Cálculo (.xlsx)",
                            f,
                            file_name=os.path.basename(res.memoria_calculo_path),
                        )

                if os.path.exists(res.rcm_path):
                    with open(res.rcm_path, "rb") as f:
                        st.download_button(
                            "📥 Baixar RCM (.docx)",
                            f,
                            file_name=os.path.basename(res.rcm_path),
                        )
            else:
                st.error(
                    "⛔ **Entrega Bloqueada pelo Auditor.** Corrija os problemas listados e reinicie o processo."
                )

            if st.button("🔄 Reiniciar Processo"):
                st.session_state.sisp_status = "IDLE"
                st.rerun()

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

    # Usando radio button horizontal em vez de tabs para manter o estado após o rerun
    sub_page = st.radio(
        "Selecione a visualização:",
        ["Chat Conversacional", "Análise de Solicitação", "Dashboard BI"],
        horizontal=True,
        key="chatbot_sub_nav",
        label_visibility="collapsed",
    )

    st.markdown("---")

    if sub_page == "Chat Conversacional":
        render_chat_interface()
    elif sub_page == "Análise de Solicitação":
        render_analysis_interface()
    elif sub_page == "Dashboard BI":
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


def render_knowledge_base_page() -> None:
    """Renderiza a página de gestão da Base de Conhecimento."""
    st.header("🧠 Base de Conhecimento")
    st.write(
        "Gerencie os documentos e manuais que alimentam a inteligência do sistema."
    )

    try:
        graph = Neo4jGraph(
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
        )
    except Exception as e:
        st.error(f"Erro ao conectar ao Neo4j: {e}")
        return

    # --- KPIs ---
    col1, col2, col3 = st.columns(3)

    # Total de Manuais
    res_manuais = graph.query("MATCH (m:Manual) RETURN count(m) as total")
    total_manuais = res_manuais[0]["total"] if res_manuais else 0
    col1.metric("Manuais Carregados", total_manuais)

    # Total de Chunks (Trechos)
    res_chunks = graph.query("MATCH (c:Chunk) RETURN count(c) as total")
    total_chunks = res_chunks[0]["total"] if res_chunks else 0
    col2.metric("Trechos Indexados", total_chunks)

    # Total de RCMs (Base Histórica)
    res_rcms = graph.query("MATCH (r:RCM) RETURN count(r) as total")
    total_rcms = res_rcms[0]["total"] if res_rcms else 0
    col3.metric("RCMs Históricas", total_rcms)

    st.markdown("---")

    # --- AÇÕES ---
    st.subheader("⚙️ Ações")
    col_act1, col_act2 = st.columns(2)

    with col_act1:
        st.info(
            "Adicione novos arquivos na pasta `data/` e clique abaixo para processar."
        )
        if st.button("🔄 Carregar/Atualizar Conhecimento"):
            with st.status("Processando ingestão de dados...", expanded=True) as status:
                try:
                    status.write("Iniciando pipeline de ingestão...")
                    ingestion = DataIngestion(
                        data_directory="data",
                        structured_data_path="data/solicitacoes.csv",
                        rcm_data_path="data/rcms_01.csv",
                    )
                    # Ingestão incremental (clear_db=False) para não apagar tudo
                    ingestion.run_ingestion(clear_db=False)
                    status.update(
                        label="✅ Conhecimento atualizado com sucesso!",
                        state="complete",
                    )
                    st.balloons()
                    # Aguarda um pouco e recarrega a página para atualizar KPIs
                    import time

                    time.sleep(2)
                    st.rerun()
                except Exception as e:
                    status.update(label="❌ Erro na ingestão", state="error")
                    st.error(f"Falha ao carregar conhecimento: {e}")

    with col_act2:
        st.info("Limpeza total da base (Cuidado: Apaga tudo!)")
        if st.button("🗑️ Limpar Base de Conhecimento", type="primary"):
            if st.checkbox("Confirmo que quero apagar todo o conhecimento do sistema."):
                with st.spinner("Limpando banco de dados..."):
                    try:
                        graph.query("MATCH (n) DETACH DELETE n")
                        st.success("Base de dados limpa com sucesso!")
                        st.rerun()
                    except Exception as e:
                        st.error(f"Erro ao limpar base: {e}")

    st.markdown("---")

    # --- LISTAGEM DE DOCUMENTOS ---
    st.subheader("📂 Documentos Indexados")

    tab1, tab2 = st.tabs(["Manuais", "RCMs"])

    with tab1:
        manuais = graph.query("MATCH (m:Manual) RETURN m.nome as nome ORDER BY m.nome")
        if manuais:
            df_manuais = pd.DataFrame(manuais)
            st.dataframe(df_manuais, use_container_width=True)
        else:
            st.info("Nenhum manual indexado.")

    with tab2:
        rcms = graph.query(
            "MATCH (r:RCM) RETURN r.id as id, r.titulo as titulo, r.status as status ORDER BY r.id DESC LIMIT 50"
        )
        if rcms:
            df_rcms = pd.DataFrame(rcms)
            st.dataframe(df_rcms, use_container_width=True)
        else:
            st.info("Nenhuma RCM indexada.")


def main() -> None:
    """Função principal da aplicação Streamlit."""
    st.set_page_config(
        page_title="RAG SYS-RH - Assistente Inteligente",
        page_icon="🤖",
        layout="wide",
    )
    load_dotenv()
    carregar_dados_faturamento()  # Garante que os dados de faturamento estão no banco

    # Inicializa o grafo e a ingestão de dados (se necessário)
    initialize_graph()

    st.title("🤖 RAG SYS-RH - Assistente Inteligente")

    # Sidebar para navegação
    st.sidebar.title("Navegação")

    # Botão de recarga manual
    if st.sidebar.button("🔄 Recarregar Conhecimento"):
        with st.sidebar.status("Recarregando dados...", expanded=True):
            initialize_graph.clear()  # Limpa o cache da inicialização
            DataIngestion(
                data_directory="data",
                structured_data_path="data/solicitacoes.csv",
                rcm_data_path="data/rcms_01.csv",
            ).run_ingestion(clear_db=False)  # Ingestão incremental
            st.success("Conhecimento atualizado!")

    page = st.sidebar.radio(
        "Escolha o módulo:",
        (
            "Chatbot & Análise",
            "Planejamento de RCM",
            "Gestão & Qualidade",
            "Gerador de Documentação",
            "Base de Conhecimento",
            "Engenharia SISP (Novo)",
            "Gerente Estratégico (BI)",
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
    elif page == "Base de Conhecimento":
        render_knowledge_base_page()
    elif page == "Engenharia SISP (Novo)":
        render_sisp_interface()
    elif page == "Gerente Estratégico (BI)":
        render_strategic_dashboard()


if __name__ == "__main__":
    main()

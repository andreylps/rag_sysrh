# src/api/v1/endpoints/dashboard.py

from datetime import datetime, timedelta
from typing import Any

from fastapi import APIRouter, Depends
from pydantic import BaseModel

# --- IMPORTAÇÃO CORRETA DA CONEXÃO NEO4J ---
# Importamos a função que retorna o cliente do grafo conectado
try:
    from src.rag_sysrh.neo4j_connection import get_graph
except ImportError as e:
    print("\n❌ ERRO CRÍTICO DE IMPORTAÇÃO NO DASHBOARD:")
    print("Não foi possível importar 'get_graph' de 'src.rag_sysrh.neo4j_connection'.")
    print(f"Detalhes: {e}\n")

    # Define uma função dummy para não quebrar a definição dos endpoints,
    # mas eles falharão se tentarem usar.
    def get_graph():
        return None


# Importe seu serviço de LLM aqui quando estiver pronto
LLMService = Any

router = APIRouter()


# --- Dependência para injeção no FastAPI ---
def get_db_session():
    """
    Dependência do FastAPI que obtém uma instância conectada do Neo4jGraph.
    Se falhar ao conectar, retorna None, forçando o uso de mocks.
    """
    try:
        # get_graph() lê as env vars e retorna o cliente conectado
        graph_client = get_graph()
        return graph_client
    except Exception as e:
        print(f"⚠️ Falha ao obter conexão com Neo4j para o dashboard: {e}")
        return None


# --- Modelos Pydantic (Schemas) ---


class DashboardFilter(BaseModel):
    """
    Modelo para o filtro de período recebido via query parameter.
    """

    period: str = "Últimos 30 dias"


class AnalysisRequest(BaseModel):
    """
    Modelo para o corpo da requisição POST de análise.
    """

    period: str


# --- Funções Auxiliares (Helper Functions) ---


def get_date_range_from_period(period: str):
    """
    Converte a string do período em um intervalo de datas YYYY-MM-DD.
    """
    today = datetime.now().date()
    if period == "Hoje":
        start_date = today
    elif period == "Últimos 7 dias":
        start_date = today - timedelta(days=7)
    elif period == "Últimos 30 dias":
        start_date = today - timedelta(days=30)
    elif period == "Este Mês":
        start_date = today.replace(day=1)
    elif period == "Último Trimestre":
        start_date = today - timedelta(days=90)
    else:
        start_date = today - timedelta(days=30)
    return start_date.strftime("%Y-%m-%d"), today.strftime("%Y-%m-%d")


# --- Endpoints ---


@router.get("/production", response_model=dict[str, Any])
async def get_production_data(
    filter: DashboardFilter = Depends(),
    db_client=Depends(get_db_session),
):
    """
    Retorna os dados detalhados para o Dashboard de Operações (7 Painéis).
    Lê diretamente dos arquivos CSV: solicitacoes.csv, rcms_01.csv, custos.csv.
    """
    import os

    import numpy as np
    import pandas as pd

    # Caminhos dos arquivos
    base_dir = os.path.dirname(
        os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        )
    )
    data_dir = os.path.join(base_dir, "data")
    solic_path = os.path.join(data_dir, "solicitacoes.csv")
    rcm_path = os.path.join(data_dir, "rcms_01.csv")
    custos_path = os.path.join(data_dir, "faturamento", "custos.csv")

    # Estrutura de resposta padrão (vazia/zerada)
    response_data = {
        "panel_demand": {},
        "panel_effort": {},
        "panel_delivery": {},
        "panel_complexity": {},
        "panel_flow": {},
        "panel_strategic": {},
        "panel_executive": {},
        "isRealData": False,
    }

    try:
        # --- CARREGAMENTO DE DADOS ---
        if not (os.path.exists(solic_path) and os.path.exists(rcm_path)):
            print("❌ Arquivos CSV principais não encontrados.")
            return response_data

        # Carrega Solicitações
        df_s = pd.read_csv(
            solic_path,
            sep=";",
            encoding="latin-1",
            skiprows=9,
            on_bad_lines="skip",
            usecols=range(10),
        )
        df_s.rename(
            columns={
                df_s.columns[0]: "id",
                df_s.columns[1]: "work_item_type",
                df_s.columns[2]: "title",
                df_s.columns[3]: "status",
                df_s.columns[4]: "assigned_to",
                df_s.columns[5]: "tipo_solicitacao",
                df_s.columns[6]: "iteration_path",
                df_s.columns[8]: "created_date",
                df_s.columns[9]: "effort",
            },
            inplace=True,
        )
        df_s["effort"] = pd.to_numeric(df_s["effort"], errors="coerce").fillna(0)

        # Carrega RCMs
        df_r = pd.read_csv(
            rcm_path, sep=";", encoding="latin-1", skiprows=1, on_bad_lines="skip"
        )
        df_r.rename(
            columns={
                df_r.columns[0]: "id",
                df_r.columns[9]: "effort",
                df_r.columns[10]: "data_prevista",
                df_r.columns[11]: "closed_date",
            },
            inplace=True,
        )

        # Carrega Custos (opcional)
        custo_pf = 850.0
        custo_hora = 150.0
        if os.path.exists(custos_path):
            try:
                df_c = pd.read_csv(custos_path, sep=",", encoding="latin-1")
                custo_pf = float(
                    df_c[df_c["tipo"] == "ponto_funcao"]["valor"].max() or 850.0
                )
                custo_hora = float(
                    df_c[df_c["tipo"] == "hora_desenvolvimento"]["valor"].max() or 150.0
                )
            except:
                pass

        # --- PROCESSAMENTO DE MÉTRICAS ---

        # 1. INDICADORES DE SOLICITAÇÕES (DEMANDA)
        total_solicitacoes = len(df_s)
        status_counts = df_s["status"].value_counts().to_dict()

        abertas = sum(
            df_s["status"]
            .str.lower()
            .isin(["new", "to do", "active", "approved", "committed"])
        )
        encerradas = sum(
            df_s["status"]
            .str.lower()
            .isin(["done", "closed", "concluido", "concluida", "removed"])
        )
        em_andamento = sum(
            df_s["status"]
            .str.lower()
            .isin(["in progress", "desenvolvimento", "testes"])
        )

        # Backlog por Time (Agora usando Iteration Path Prefix)
        backlog_by_team = df_s[
            ~df_s["status"]
            .str.lower()
            .isin(["done", "closed", "concluido", "concluida", "removed"])
        ].copy()

        # Extrai o prefixo do Iteration Path (ex: "FUNC/" de "FUNC/S1")
        def extract_prefix(path):
            import re

            if pd.isna(path):
                return "Indefinido"
            # Split by any separator (\ or /) and filter empty
            parts = [p for p in re.split(r"[\\/]", str(path)) if p]
            return parts[0] + "/" if len(parts) > 0 else str(path)

        backlog_by_team["team_prefix"] = backlog_by_team["iteration_path"].apply(
            extract_prefix
        )
        backlog_team_counts = (
            backlog_by_team["team_prefix"].value_counts().head(5).to_dict()
        )

        # Classificação
        type_counts = df_s["tipo_solicitacao"].value_counts().head(5).to_dict()

        # Extrair Cliente/Area do Work Item Type ou Title
        df_s["area"] = (
            df_s["work_item_type"]
            .astype(str)
            .str.replace("SOLICITACAO ", "", regex=False)
        )
        area_counts = df_s["area"].value_counts().head(5).to_dict()

        response_data["panel_demand"] = {
            "total": total_solicitacoes,
            "open": int(abertas),
            "closed": int(encerradas),
            "in_progress": int(em_andamento),
            "backlog_by_team": [
                {"name": k, "value": v} for k, v in backlog_team_counts.items()
            ],
            "by_type": [{"name": k, "value": v} for k, v in type_counts.items()],
            "by_area": [{"name": k, "value": v} for k, v in area_counts.items()],
        }

        # 2. INDICADORES DE ESFORÇO
        total_effort = df_s["effort"].sum()
        # Capacidade (Mock: 5 devs * 160h = 800h/mês)
        capacity = 800

        effort_by_type = (
            df_s.groupby("tipo_solicitacao")["effort"].sum().head(5).to_dict()
        )

        # Produtividade (Pontos de Função Entregues - Mockado pois não temos campo explícito de PF, usando Effort como proxy)
        productivity = total_effort / 5  # Effort per dev (avg)

        response_data["panel_effort"] = {
            "total_effort": float(total_effort),
            "capacity": capacity,
            "capacity_usage": min(
                100, int((total_effort / (capacity * 12)) * 100)
            ),  # Assuming total effort is historical (all time), scaling capacity roughly
            "effort_by_type": [
                {"name": k, "value": float(v)} for k, v in effort_by_type.items()
            ],
            "productivity_per_dev": float(productivity),
        }

        # 3. INDICADORES DE ENTREGAS
        # Usando RCMs para datas de entrega
        df_r["closed_date"] = pd.to_datetime(
            df_r["closed_date"], errors="coerce", dayfirst=True
        )
        df_r["data_prevista"] = pd.to_datetime(
            df_r["data_prevista"], errors="coerce", dayfirst=True
        )

        entregas_validas = df_r.dropna(subset=["closed_date"])
        total_entregas = len(entregas_validas)

        # No Prazo
        no_prazo = entregas_validas[
            entregas_validas["closed_date"] <= entregas_validas["data_prevista"]
        ]
        percent_no_prazo = (
            (len(no_prazo) / total_entregas * 100) if total_entregas > 0 else 0
        )

        # Throughput (Entregas por Mês)
        if not entregas_validas.empty:
            throughput = entregas_validas.groupby(
                entregas_validas["closed_date"].dt.to_period("M")
            ).size()
            throughput_data = [
                {"name": str(p), "value": int(v)} for p, v in throughput.tail(6).items()
            ]
        else:
            throughput_data = []

        response_data["panel_delivery"] = {
            "total_deliveries": total_entregas,
            "on_time_percentage": int(percent_no_prazo),
            "throughput_history": throughput_data,
            "avg_delay_days": 2.5,  # Mock, difícil calcular sem dados precisos de atraso
        }

        # 4. INDICADORES DE COMPLEXIDADE
        # Binning Effort
        conditions = [
            (df_s["effort"] <= 40),
            (df_s["effort"] > 40) & (df_s["effort"] <= 100),
            (df_s["effort"] > 100),
        ]
        choices = ["Baixa", "Média", "Alta"]
        df_s["complexity"] = np.select(conditions, choices, default="Desconhecida")
        complexity_counts = df_s["complexity"].value_counts().to_dict()

        response_data["panel_complexity"] = {
            "distribution": [
                {"name": k, "value": v} for k, v in complexity_counts.items()
            ],
            "avg_effort": float(df_s["effort"].mean()),
            "high_complexity_count": int(complexity_counts.get("Alta", 0)),
        }

        # 5. INDICADORES DE FLUXO (LEAD TIME)
        # Lead Time = Closed Date - Created Date (precisa de join ou dados no mesmo arquivo)
        # RCMs tem Closed Date, mas não Created Date confiável (tem DataPrevista).
        # Solicitacoes tem Created Date, mas não Closed Date.
        # Vamos usar RCMs assumindo Created Date ~ DataPrevista - 30 dias (Mock) ou usar dados disponíveis
        # Melhor: Usar Solicitacoes 'Created Date' e cruzar com RCMs se possível, ou mockar Lead Time baseado em Effort.

        # Mocking Lead Time distribution based on Effort (proxy)
        lead_time_avg = df_s["effort"].mean() / 8  # Assuming 8h/day work

        response_data["panel_flow"] = {
            "lead_time_avg": float(lead_time_avg),
            "cycle_time_avg": float(
                lead_time_avg * 0.7
            ),  # Cycle time usually 70% of lead time
            "wip": int(em_andamento),
            "efficiency": 65,  # Mock
        }

        # 6. INDICADORES ESTRATÉGICOS
        # Custo Estimado = Effort * Rate
        def calculate_cost(row):
            tipo = str(row.get("tipo_solicitacao", "")).lower()
            effort = float(row.get("effort", 0))
            if tipo in ["evolutivo", "melhoria", "projeto"]:
                return effort * custo_pf
            return effort * custo_hora

        df_s["estimated_cost"] = df_s.apply(calculate_cost, axis=1)
        total_cost = df_s["estimated_cost"].sum()

        response_data["panel_strategic"] = {
            "total_estimated_cost": float(total_cost),
            "roi_proxy": float(total_cost * 1.5),  # Mock ROI
            "items_at_risk": len(df_s[df_s["status"] == "Blocked"]),  # Mock status
        }

        # 7. VISÃO EXECUTIVA (RESUMO)
        response_data["panel_executive"] = {
            "backlog_total": int(total_solicitacoes - encerradas),
            "deliveries_month": int(throughput_data[-1]["value"])
            if throughput_data
            else 0,
            "lead_time_avg": float(lead_time_avg),
            "on_time_percent": int(percent_no_prazo),
            "effort_vs_capacity": f"{int(total_effort)} / {capacity * 12}",
        }

        response_data["isRealData"] = True
        print("✅ Dados do Dashboard de Operações (7 Painéis) gerados com sucesso!")

    except Exception as e:
        print(f"❌ Erro ao gerar dados de operações: {e}")
        import traceback

        traceback.print_exc()

    return response_data


@router.get("/billing", response_model=dict[str, Any])
async def get_billing_data(
    filter: DashboardFilter = Depends(),
    db_client=Depends(get_db_session),
):
    """
    Retorna os dados financeiros detalhados para o Dashboard Financeiro (4 Painéis).
    Calcula métricas reais a partir de solicitacoes.csv e custos.csv.
    """
    import os

    import pandas as pd

    # Caminhos dos arquivos
    base_dir = os.path.dirname(
        os.path.dirname(
            os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
        )
    )
    data_dir = os.path.join(base_dir, "data")
    solic_path = os.path.join(data_dir, "solicitacoes.csv")
    custos_path = os.path.join(data_dir, "faturamento", "custos.csv")

    response_data = {
        "panel_executive": {},
        "panel_productivity": {},
        "panel_costs": {},
        "panel_risks": {},
        "isRealData": False,
    }

    try:
        if os.path.exists(solic_path) and os.path.exists(custos_path):
            # --- 1. CARREGAMENTO E PREPARAÇÃO ---
            df_s = pd.read_csv(
                solic_path, sep=";", encoding="latin-1", skiprows=1, on_bad_lines="skip"
            )
            df_s.rename(
                columns={
                    df_s.columns[0]: "id",
                    df_s.columns[1]: "work_item_type",
                    df_s.columns[2]: "title",
                    df_s.columns[4]: "assigned_to",
                    df_s.columns[5]: "tipo_solicitacao",
                    df_s.columns[9]: "effort",
                },
                inplace=True,
            )

            df_s["effort"] = pd.to_numeric(df_s["effort"], errors="coerce").fillna(0)

            # Carrega Custos
            df_c = pd.read_csv(custos_path, sep=",", encoding="latin-1")
            custo_pf = float(
                df_c[df_c["tipo"] == "ponto_funcao"]["valor"].max() or 850.0
            )
            custo_hora = float(
                df_c[df_c["tipo"] == "hora_desenvolvimento"]["valor"].max() or 150.0
            )

            # --- 2. CÁLCULO DE RECEITA E CUSTO ---
            def calcular_financeiro(row):
                tipo = str(row.get("tipo_solicitacao", "")).lower()
                effort = float(row.get("effort", 0))

                # Receita
                if tipo in ["evolutivo", "melhoria", "projeto"]:
                    receita = effort * custo_pf
                else:
                    receita = effort * custo_hora

                # Custo (Proxy: 70% da receita para margem de 30%)
                custo = receita * 0.7

                return pd.Series([receita, custo], index=["receita", "custo"])

            df_s[["receita", "custo"]] = df_s.apply(calcular_financeiro, axis=1)
            df_s["margem"] = df_s["receita"] - df_s["custo"]

            # Extração de Cliente
            df_s["cliente"] = (
                df_s["work_item_type"]
                .astype(str)
                .str.replace("SOLICITACAO ", "", regex=False)
            )

            # --- 3. PAINEL 1: EXECUTIVO ---
            receita_total = df_s["receita"].sum()
            custo_total = df_s["custo"].sum()
            margem_liquida = receita_total - custo_total
            ticket_medio = receita_total / len(df_s) if len(df_s) > 0 else 0

            # Top Clientes
            top_clientes = (
                df_s.groupby("cliente")["receita"]
                .sum()
                .sort_values(ascending=False)
                .head(5)
            )
            top_clientes_list = [
                {"name": k, "value": float(v)} for k, v in top_clientes.items()
            ]

            response_data["panel_executive"] = {
                "total_revenue": float(receita_total),
                "net_margin": float(margem_liquida),
                "gross_margin": float(
                    receita_total - (custo_total * 0.8)
                ),  # Margem bruta um pouco maior
                "ticket_avg": float(ticket_medio),
                "top_clients": top_clientes_list,
                "revenue_vs_target": [  # Mock vs Target
                    {"name": "Previsto", "value": float(receita_total * 1.1)},
                    {"name": "Realizado", "value": float(receita_total)},
                ],
            }

            # --- 4. PAINEL 2: PRODUTIVIDADE X FINANCEIRO ---
            # Valor por Sprint (Mockando sprints com base em datas ou aleatório para demo)
            # Como não temos sprints claras no CSV, vamos agrupar por mês de criação como proxy
            # df_s['month'] = pd.to_datetime(df_s['created_date'], dayfirst=True).dt.to_period('M')
            # value_per_sprint = df_s.groupby('month')['receita'].sum().mean()
            value_per_sprint = receita_total / 12  # Média mensal simples

            # Valor por Dev
            devs_count = df_s["assigned_to"].nunique()
            value_per_dev = receita_total / devs_count if devs_count > 0 else 0

            # Custo x Margem por Time
            team_metrics = (
                df_s.groupby("assigned_to")[["custo", "margem"]]
                .sum()
                .sort_values(by="margem", ascending=False)
                .head(5)
            )
            cost_vs_margin = [
                {
                    "name": k.split(" ")[0],
                    "cost": float(v["custo"]),
                    "margin": float(v["margem"]),
                }
                for k, v in team_metrics.iterrows()
            ]

            response_data["panel_productivity"] = {
                "value_per_sprint": float(value_per_sprint),
                "value_per_dev": float(value_per_dev),
                "conversion_rate": 85.5,  # Mock: % de entregas que viraram faturamento
                "cost_vs_margin": cost_vs_margin,
            }

            # --- 5. PAINEL 3: CUSTOS E EFICIÊNCIA ---
            cost_per_demand = custo_total / len(df_s) if len(df_s) > 0 else 0
            cost_per_hour = (
                custo_total / df_s["effort"].sum() if df_s["effort"].sum() > 0 else 0
            )

            response_data["panel_costs"] = {
                "cost_per_demand": float(cost_per_demand),
                "cost_per_hour": float(cost_per_hour),
                "rework_cost": float(
                    custo_total * 0.15
                ),  # Estimativa de 15% de retrabalho
                "financial_deviation": float(custo_total * 0.05),  # 5% de desvio
            }

            # --- 6. PAINEL 4: RISCOS FINANCEIROS ---
            # Concentração (Top 1 Cliente / Total)
            top_1_revenue = top_clientes.iloc[0] if not top_clientes.empty else 0
            concentration = (
                (top_1_revenue / receita_total * 100) if receita_total > 0 else 0
            )

            # Projetos com Margem Negativa (Simulando alguns)
            # Na prática, pegaria os que custo > receita, mas nosso cálculo forçou margem positiva.
            # Vamos pegar os de menor margem relativa.
            df_s["margem_pct"] = df_s["margem"] / df_s["receita"]
            low_margin_projects = df_s.nsmallest(5, "margem_pct")
            negative_projects = [
                {"name": f"Solicitação {row['id']}", "margin": float(row["margem"])}
                for _, row in low_margin_projects.iterrows()
            ]

            response_data["panel_risks"] = {
                "concentration_pct": float(concentration),
                "deficit_contracts": 2,  # Mock
                "negative_projects": negative_projects,
            }

            response_data["isRealData"] = True
            print(
                f"✅ Dados Financeiros (4 Painéis) calculados com sucesso. Receita Total: {receita_total}"
            )

    except Exception as e:
        print(f"❌ Erro ao calcular dados financeiros detalhados: {e}")
        import traceback

        traceback.print_exc()

    return response_data


@router.post("/analysis", response_model=dict[str, Any])
async def get_analysis_data(
    request: AnalysisRequest, db_client=Depends(get_db_session)
):
    """
    Gera uma análise de BI usando o Agente de IA (LLM + Neo4j).
    Coleta os dados dos outros endpoints e envia para o LLM analisar.
    """
    try:
        from src.rag_sysrh.agente_bi import AgenteBI

        # 1. Coleta dados de Produção e Faturamento para o contexto
        # Precisamos instanciar o filtro manualmente
        filtro = DashboardFilter(period=request.period)

        # Chama as funções diretamente (reutilizando a lógica)
        # Note: Como são async, precisamos de await. Como dependem de db_client, passamos explicitamente.
        prod_data = await get_production_data(filter=filtro, db_client=db_client)
        billing_data = await get_billing_data(filter=filtro, db_client=db_client)

        contexto_dados = {
            "periodo": request.period,
            "producao": prod_data,
            "financeiro": billing_data,
        }

        # 2. Instancia o agente e pede análise do JSON
        agente = AgenteBI()
        data = await agente.analisar_dados_json(contexto_dados)

        return data

    except Exception as e:
        print(f"❌ Erro no endpoint de análise: {e}")
        return {
            "resumo": "Não foi possível gerar a análise de IA no momento.",
            "analiseProducao": {"pontosFortes": [], "atencao": []},
            "analiseFinanceira": {"insights": []},
            "recomendacoes": [],
            "alertas": [
                {"titulo": "Erro de Conexão", "descricao": str(e), "tipo": "erro"}
            ],
            "previsao": {
                "metrica1Label": "-",
                "metrica1Value": "-",
                "metrica2Label": "-",
                "metrica2Value": "-",
            },
        }

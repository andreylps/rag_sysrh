# src/api/v1/endpoints/dashboard.py

import asyncio
import random
from datetime import datetime, timedelta
from typing import Any, Dict, List

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


@router.get("/production", response_model=Dict[str, Any])
async def get_production_data(
    filter: DashboardFilter = Depends(),
    db_client=Depends(get_db_session),
):
    """
    Retorna os dados agregados para a aba de Produção (agora Governança) do Dashboard.
    Busca KPIs reais de Solicitações e RCMs no Neo4j.
    """
    if not db_client:
        print("⚠️ AVISO: Cliente Neo4j é None. Usando dados de MOCK.")

    # --- 1. QUERY REAL PARA OS KPIs DE GOVERNANÇA ---
    # Ajuste: Status real encontrado no banco é 'CONCLUIDA'
    cypher_kpis = """
        MATCH (s:Solicitacao)
        WITH count(s) as total_solicitacoes,
             sum(CASE WHEN toLower(toString(s.status)) IN ['concluido', 'concluida', 'fechado', 'entregue'] THEN 1 ELSE 0 END) as fechadas,
             sum(s.horas_realizadas) as total_horas
        
        MATCH (r:RCM)
        WITH total_solicitacoes, fechadas, total_horas, count(r) as total_rcms,
             sum(CASE WHEN 'NeedsRevision' IN labels(r) THEN 1 ELSE 0 END) as rcms_revisao

        RETURN
            CASE WHEN total_solicitacoes > 0 THEN (toFloat(fechadas) / total_solicitacoes) * 100 ELSE 0 END as taxa_eficiencia,
            95.0 as sla_compliance,
            88.5 as performance_index,
            CASE WHEN total_rcms > 0 THEN ((total_rcms - rcms_revisao) / toFloat(total_rcms)) * 100 ELSE 100 END as qualidade_rcm,
            total_solicitacoes,
            fechadas,
            total_rcms
    """

    # Inicializa com valores seguros
    real_oee = 0.0
    real_avail = 0.0
    real_perf = 0.0
    real_qual = 0.0

    total_plan_fmt = "0"
    total_prod_fmt = "0"
    total_rej_fmt = "0"

    ranking_data = []

    using_real_data = False

    # --- 2. EXECUÇÃO NO NEO4J ---
    if db_client:
        try:
            # result_list: List[Dict] = db_client.query(cypher_kpis)
            result_list: List[Dict] = await asyncio.to_thread(
                db_client.query, cypher_kpis
            )

            if result_list and len(result_list) > 0:
                record = result_list[0]

                real_oee = record.get("taxa_eficiencia") or 0.0
                real_avail = record.get("sla_compliance") or 0.0
                real_perf = record.get("performance_index") or 0.0
                real_qual = record.get("qualidade_rcm") or 0.0

                t_solic = record.get("total_solicitacoes") or 0
                t_fechadas = record.get("fechadas") or 0
                t_rcms = record.get("total_rcms") or 0

                # Mapeamento para os cards pequenos
                # Qtd Planejada -> Total Solicitações
                # Qtd Produzida -> Solicitações Fechadas
                # Qtd Rejeitada -> Total RCMs (ou RCMs com erro)
                total_plan_fmt = str(int(t_solic))
                total_prod_fmt = str(int(t_fechadas))
                total_rej_fmt = str(int(t_rcms))

                using_real_data = True
                print("✅ Dados de Governança recuperados do Neo4j com sucesso!")

            # Query para Ranking de Rejeições (agora Bugs por Cliente)
            cypher_ranking = """
                MATCH (s:Solicitacao)-[:ASSOCIADA_A]->(c:Cliente)
                WHERE toLower(toString(s.tipo_solicitacao)) IN ['corretiva', 'bug', 'erro']
                RETURN c.nome as name, count(s) as value
                ORDER BY value DESC
                LIMIT 5
            """
            # ranking_list = db_client.query(cypher_ranking)
            ranking_list = await asyncio.to_thread(db_client.query, cypher_ranking)
            ranking_data = []
            max_val = 1
            if ranking_list:
                max_val = max([r["value"] for r in ranking_list]) or 1
                for r in ranking_list:
                    ranking_data.append(
                        {
                            "name": r["name"],
                            "value": r["value"],
                            "formattedValue": str(r["value"]),
                            "percentage": int((r["value"] / max_val) * 100),
                        }
                    )

            if not ranking_data:
                ranking_data = [
                    {
                        "name": "Sem bugs registrados",
                        "value": 0,
                        "formattedValue": "0",
                        "percentage": 0,
                    }
                ]

        except Exception as e:
            print(f"❌ Erro crítico ao consultar Neo4j: {e}")

    # --- 3. MONTAGEM DO RETORNO ---
    hybrid_data = {
        "oee": real_oee,
        "availability": real_avail,
        "performance": real_perf,
        "quality": real_qual,
        "isRealData": using_real_data,
        "qtdPlanejada": total_plan_fmt,
        "qtdPlanejadaUnit": "Solic.",
        "qtdProduzida": total_prod_fmt,
        "qtdProduzidaUnit": "Entregues",
        "qtdProduzidaTrend": "up",
        "qtdProduzidaChange": "+5%",
        "qtdRejeitada": total_rej_fmt,
        "qtdRejeitadaUnit": "RCMs",
        "qtdRejeitadaTrend": "down",
        "qtdRejeitadaChange": "-2%",
        # Mocks visuais para gráficos de linha (sparklines)
        "oeeHistory": [
            {"index": i, "value": 70 + random.random() * 15} for i in range(50)
        ],
        "availabilityHistory": [{"v": 90 + random.random() * 10} for _ in range(30)],
        "performanceHistory": [{"v": 80 + random.random() * 10} for _ in range(30)],
        "qualityHistory": [{"v": 88 + random.random() * 10} for _ in range(30)],
        "productionOverTime": [
            {"month": "Jan", "value": 120, "target": 100},
            {"month": "Fev", "value": 135, "target": 110},
            {"month": "Mar", "value": 110, "target": 115},
        ],
        "rejectionRanking": ranking_data
        if using_real_data
        else [
            {
                "name": "Aguardando dados...",
                "value": 0,
                "formattedValue": "-",
                "percentage": 0,
            }
        ],
        "occurrencesRanking": [
            {"name": "Erro de Acesso", "value": 13},
            {"name": "Lentidão", "value": 10},
        ],
    }
    return hybrid_data


@router.get("/billing", response_model=Dict[str, Any])
async def get_billing_data(
    filter: DashboardFilter = Depends(),
    db_client=Depends(get_db_session),
):
    """
    Retorna os dados financeiros reais calculados a partir das Solicitações e Custos.
    """

    # Inicializa com mocks caso o banco falhe
    receita_total_val = 0.0
    custo_total_val = 0.0
    lucro_val = 0.0

    top_clientes = []
    composicao_custos = []  # noqa: F841
    evolucao_financeira = []  # noqa: F841

    using_real_data = False

    if db_client:
        try:
            # 1. Cálculo de Receita Total (Soma dos custos cobráveis)
            # Regra: Evolutivo = Pontos de Função * Valor PF
            #        Outros = Horas * Valor Hora (Fallback para Effort se Horas for 0/Null)
            cypher_billing = """
                MATCH (s:Solicitacao)
                OPTIONAL MATCH (c_pf:Custo {tipo: 'ponto_funcao'})
                OPTIONAL MATCH (c_h:Custo {tipo: 'hora_desenvolvimento'})
                
                WITH s, c_pf, c_h,
                     CASE 
                        WHEN toLower(toString(s.tipo_solicitacao)) IN ['evolutivo', 'melhoria', 'projeto'] 
                        THEN coalesce(s.effort, 0) * coalesce(c_pf.valor, 0)
                        ELSE coalesce(s.horas_realizadas, s.effort, 0) * coalesce(c_h.valor, 0)
                     END as valor_solicitacao
                
                RETURN sum(valor_solicitacao) as receita_total
            """

            # result = db_client.query(cypher_billing)
            result = await asyncio.to_thread(db_client.query, cypher_billing)
            if result:
                receita_total_val = result[0].get("receita_total") or 0.0
                # Simulando margem de lucro de 20% e custos de 80%
                custo_total_val = receita_total_val * 0.8
                lucro_val = receita_total_val * 0.2
                using_real_data = True  # noqa: F841
                print(
                    f"✅ Dados Financeiros recuperados: Receita R$ {receita_total_val}"
                )

            # 2. Top Clientes por Receita
            cypher_top_clients = """
                MATCH (s:Solicitacao)-[:ASSOCIADA_A]->(c:Cliente)
                OPTIONAL MATCH (custo_pf:Custo {tipo: 'ponto_funcao'})
                OPTIONAL MATCH (custo_h:Custo {tipo: 'hora_desenvolvimento'})
                
                WITH s, c, custo_pf, custo_h,
                     CASE 
                        WHEN toLower(toString(s.tipo_solicitacao)) IN ['evolutivo', 'melhoria', 'projeto'] 
                        THEN coalesce(s.effort, 0) * coalesce(custo_pf.valor, 0)
                        ELSE coalesce(s.horas_realizadas, s.effort, 0) * coalesce(custo_h.valor, 0)
                     END as valor
                
                RETURN c.nome as name, sum(valor) as total_valor
                ORDER BY total_valor DESC
                LIMIT 5
            """
            # clients_result = db_client.query(cypher_top_clients)
            clients_result = await asyncio.to_thread(
                db_client.query, cypher_top_clients
            )
            if clients_result:
                for r in clients_result:
                    val = r["total_valor"]
                    fmt = (
                        f"R$ {val / 1000000:.1f} Mi"
                        if val > 1000000
                        else f"R$ {val / 1000:.1f} Mil"
                    )
                    top_clientes.append(
                        {"name": r["name"], "value": val, "formattedValue": fmt}
                    )

        except Exception as e:
            print(f"❌ Erro ao calcular faturamento: {e}")

    # Formata valores totais
    receita_fmt = f"{receita_total_val / 1000000:.1f}".replace(".", ",")
    custo_fmt = f"{custo_total_val / 1000000:.1f}".replace(".", ",")
    lucro_fmt = f"{lucro_val / 1000000:.1f}".replace(".", ",")

    mock_data = {
        "receitaTotal": receita_fmt,
        "receitaTotalUnit": "Mi",
        "receitaTotalTrend": "up",
        "receitaTotalChange": "+12%",
        "custoOperacional": custo_fmt,
        "custoOperacionalUnit": "Mi",
        "custoOperacionalTrend": "down",
        "custoOperacionalChange": "-5%",
        "lucroLiquido": lucro_fmt,
        "lucroLiquidoUnit": "Mi",
        "lucroLiquidoTrend": "up",
        "lucroLiquidoChange": "+25%",
        # Dados simulados para gráficos (difícil extrair histórico sem datas precisas nos CSVs de exemplo)
        "evolucaoFinanceira": [
            {
                "month": "Jan",
                "receita": receita_total_val / 3000000,
                "custo": custo_total_val / 3000000,
                "lucro": lucro_val / 3000000,
            },
            {
                "month": "Fev",
                "receita": receita_total_val / 3000000 * 1.1,
                "custo": custo_total_val / 3000000 * 1.05,
                "lucro": lucro_val / 3000000 * 1.2,
            },
            {
                "month": "Mar",
                "receita": receita_total_val / 3000000 * 0.9,
                "custo": custo_total_val / 3000000 * 0.95,
                "lucro": lucro_val / 3000000 * 0.8,
            },
        ],
        "composicaoCustos": [
            {"name": "Desenvolvimento", "value": 60, "color": "#ef4444"},
            {"name": "Gestão", "value": 20, "color": "#f97316"},
            {"name": "Infraestrutura", "value": 20, "color": "#3b82f6"},
        ],
        "topClientes": top_clientes
        if top_clientes
        else [{"name": "Sem dados", "value": 0, "formattedValue": "R$ 0"}],
    }
    return mock_data


@router.post("/analysis", response_model=Dict[str, Any])
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

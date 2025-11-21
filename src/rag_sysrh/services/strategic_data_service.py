import logging
from typing import Any, Dict, List, Optional

import numpy as np
import pandas as pd

logger = logging.getLogger(__name__)


class StrategicDataService:
    """
    Serviço de Inteligência de Dados para o Agente Gerente Estratégico.
    Responsável por carregar, limpar e calcular KPIs a partir do CSV de solicitações.
    """

    def __init__(self, csv_path: str = "data/solicitacoes.csv"):
        self.csv_path = csv_path
        self.df = self._load_and_clean_data()

    def _load_and_clean_data(self) -> pd.DataFrame:
        """
        Carrega o CSV, encontra o cabeçalho correto e limpa os dados.
        """
        try:
            # Tenta ler o arquivo procurando a linha de cabeçalho
            # Lendo as primeiras linhas para achar onde começa "ID;"
            with open(self.csv_path, "r", encoding="latin1") as f:
                lines = f.readlines()

            header_row = 0
            for i, line in enumerate(lines):
                if line.strip().startswith("ID;"):
                    header_row = i
                    break

            # Carrega o dataframe
            df = pd.read_csv(
                self.csv_path, sep=";", encoding="latin1", skiprows=header_row
            )

            # Normalização de colunas
            # Mapeamento de colunas esperadas para nomes internos
            column_map = {
                "ID": "id",
                "Work Item Type": "tipo",
                "Title": "titulo",
                "State": "estado",
                "Assigned To": "responsavel",
                "Created Date": "data_criacao",
                "Closed Date": "data_fechamento",
                "Area Path": "area",  # Usado para identificar Time/Cliente se não houver coluna específica
                "Iteration Path": "sprint",
                "Effort": "esforco",  # PF ou Horas
                "Reason": "motivo",  # Motivo de recusa/fechamento
            }

            # Renomeia colunas que existem
            df = df.rename(
                columns={k: v for k, v in column_map.items() if k in df.columns}
            )

            # Tratamento de Datas
            # Tenta encontrar colunas de data se os nomes padrão não baterem
            date_cols = [
                c for c in df.columns if "date" in c.lower() or "data" in c.lower()
            ]
            for col in date_cols:
                df[col] = pd.to_datetime(df[col], errors="coerce", dayfirst=True)

            # Se não tiver data_criacao mapeada, tenta usar a primeira coluna de data encontrada
            if "data_criacao" not in df.columns and date_cols:
                df["data_criacao"] = df[date_cols[0]]

            # Criação de Colunas Derivadas

            # 1. Time e Cliente (Extração heurística do Area Path ou Iteration Path se não houver coluna)
            # Ex: "Projeto\Time\Cliente"
            if "area" in df.columns:
                # Mock de lógica de extração - Ajustar conforme dados reais
                # Assumindo formato: Projeto \ Time \ Cliente ou algo similar
                df["time_extraido"] = df["area"].apply(
                    lambda x: str(x).split("\\")[1]
                    if pd.notnull(x) and len(str(x).split("\\")) > 1
                    else "GERAL"
                )
                df["cliente_extraido"] = df["area"].apply(
                    lambda x: str(x).split("\\")[2]
                    if pd.notnull(x) and len(str(x).split("\\")) > 2
                    else "PADRAO"
                )
            else:
                df["time_extraido"] = "TIME_PADRAO"
                df["cliente_extraido"] = "CLIENTE_PADRAO"

            # 2. Lead Time (Dias)
            if "data_fechamento" in df.columns and "data_criacao" in df.columns:
                df["lead_time"] = (df["data_fechamento"] - df["data_criacao"]).dt.days
            else:
                # Simula Lead Time para demonstração se não tiver dados
                df["lead_time"] = np.random.randint(1, 30, size=len(df))

            # 3. Status Normalizado
            # Mapeia status do TFS para status simplificados
            status_map = {
                "New": "Backlog",
                "Approved": "Backlog",
                "Committed": "Em Andamento",
                "Done": "Concluido",
                "Removed": "Cancelado",
                "To Do": "Backlog",
                "In Progress": "Em Andamento",
            }
            df["status_simplificado"] = df["estado"].map(status_map).fillna("Outros")

            return df

        except Exception as e:
            logger.error(f"Erro ao carregar dados: {e}")
            # Retorna DF vazio com colunas mínimas para não quebrar
            return pd.DataFrame(
                columns=[
                    "id",
                    "tipo",
                    "titulo",
                    "estado",
                    "data_criacao",
                    "lead_time",
                    "time_extraido",
                    "cliente_extraido",
                ]
            )

    def _filter_data(
        self,
        period: str = "30d",
        team: Optional[str] = None,
        client: Optional[str] = None,
    ) -> pd.DataFrame:
        """Filtra o DataFrame base por período, time e cliente."""
        df_filtered = self.df.copy()

        # Filtro de Período (Baseado na data de criação)
        if (
            "data_criacao" in df_filtered.columns
            and not pd.api.types.is_datetime64_any_dtype(df_filtered["data_criacao"])
        ):
            df_filtered["data_criacao"] = pd.to_datetime(
                df_filtered["data_criacao"], errors="coerce", dayfirst=True
            )

        today = pd.Timestamp.now()
        if period == "30d":
            start_date = today - pd.Timedelta(days=30)
            df_filtered = df_filtered[df_filtered["data_criacao"] >= start_date]
        elif period == "current_month":
            start_date = today.replace(day=1)
            df_filtered = df_filtered[df_filtered["data_criacao"] >= start_date]
        # Adicionar mais filtros conforme necessário

        if team and team != "Todos":
            df_filtered = df_filtered[df_filtered["time_extraido"] == team]

        if client and client != "Todos":
            df_filtered = df_filtered[df_filtered["cliente_extraido"] == client]

        return df_filtered

    def get_operational_health_scan(self, period: str = "30d") -> Dict[str, Any]:
        """Retorna KPIs globais e dados para heatmap."""
        df = self._filter_data(period)

        # KPIs Globais
        total_demandas = len(df)
        entregues = len(df[df["status_simplificado"] == "Concluido"])
        taxa_entrega = (entregues / total_demandas * 100) if total_demandas > 0 else 0
        lead_time_medio = df[df["status_simplificado"] == "Concluido"][
            "lead_time"
        ].mean()
        if pd.isna(lead_time_medio):
            lead_time_medio = 0

        # Dados para Heatmap (Eficiência por Time x Cliente)
        # Eficiência = Entregues / Total
        heatmap_data = []
        if not df.empty:
            grouped = (
                df.groupby(["time_extraido", "cliente_extraido"])
                .agg(
                    total=("id", "count"),
                    entregues=(
                        "status_simplificado",
                        lambda x: (x == "Concluido").sum(),
                    ),
                )
                .reset_index()
            )

            grouped["eficiencia"] = (
                grouped["entregues"] / grouped["total"] * 100
            ).round(1)
            heatmap_data = grouped.to_dict("records")

        return {
            "kpis": {
                "total_demandas": total_demandas,
                "entregues": entregues,
                "taxa_entrega": round(taxa_entrega, 1),
                "lead_time_medio": round(lead_time_medio, 1),
            },
            "heatmap_data": heatmap_data,
        }

    def get_lead_time_trend(
        self, team: str, client: str, period: str = "90d"
    ) -> List[Dict]:
        """Retorna série temporal de Lead Time semanal."""
        df = self._filter_data(period, team, client)
        df_concluido = df[df["status_simplificado"] == "Concluido"].copy()

        if df_concluido.empty:
            return []

        # Agrupa por semana
        df_concluido["semana"] = (
            df_concluido["data_fechamento"]
            .dt.to_period("W")
            .apply(lambda r: r.start_time)
        )
        trend = df_concluido.groupby("semana")["lead_time"].mean().reset_index()

        return trend.to_dict("records")

    def get_bottleneck_analysis(self, team: str, client: str) -> List[Dict]:
        """
        Retorna tempo médio em cada etapa.
        Como não temos log de transição de estados detalhado no CSV simples,
        vamos simular/estimar baseado no 'State' atual das demandas em aberto
        ou usar dados mockados para demonstração da funcionalidade.
        """
        # Mock para demonstração - Em produção, precisaria de histórico de work items
        stages = ["Análise", "Desenvolvimento", "Testes", "Validação Cliente"]

        # Gera dados aleatórios mas consistentes com o filtro
        import random

        random.seed(len(team) + len(client))  # Seed determinística baseada nos inputs

        data = []
        for stage in stages:
            data.append({"etapa": stage, "tempo_medio_dias": random.randint(2, 10)})

        return data

    def get_rejection_reasons_summary(self, team: str, client: str) -> List[Dict]:
        """Retorna sumário de motivos de recusa/cancelamento."""
        df = self._filter_data("90d", team, client)
        df_cancel = df[df["status_simplificado"] == "Cancelado"]

        if df_cancel.empty:
            return []

        # Se tiver coluna 'motivo', usa. Senão, mocka ou usa 'Title' como proxy
        if "motivo" in df_cancel.columns:
            counts = df_cancel["motivo"].value_counts().reset_index()
            counts.columns = ["motivo", "quantidade"]
            return counts.to_dict("records")
        else:
            # Mock de motivos comuns
            motivos = [
                "Especificação Incompleta",
                "Duplicado",
                "Inviabilidade Técnica",
                "Cancelado pelo Cliente",
            ]
            import random

            data = []
            for m in motivos:
                data.append({"motivo": m, "quantidade": random.randint(1, 5)})
            return data

    def get_financial_kpis(self, client: str, period: str) -> Dict[str, float]:
        """
        Retorna KPIs financeiros estimados.
        PF Total * Valor Hora (Mock)
        """
        df = self._filter_data(period, client=client)
        df_entregue = df[df["status_simplificado"] == "Concluido"]

        # Tenta pegar esforço, se não tiver, assume média
        if "esforco" in df_entregue.columns:
            pf_total = df_entregue["esforco"].sum()
        else:
            pf_total = len(df_entregue) * 10  # Assume 10 PF médio por demanda

        valor_pf_mock = 500.00  # R$ 500/PF
        faturamento_estimado = pf_total * valor_pf_mock

        return {
            "faturamento_realizado": faturamento_estimado,
            "meta_faturamento": faturamento_estimado * 1.2,  # Meta sempre 20% acima
        }

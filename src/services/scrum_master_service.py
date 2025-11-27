import glob
import json
import logging
import os
from datetime import datetime, timedelta
from typing import List

from src.config.slas import CRITICAL_SLA_TYPES, ISSUE_SLA_HOURS
from src.core.quality_alerts import add_alert
from src.schemas.sprint import Sprint, SprintReport, SprintSnapshot, SprintStatus
from src.services.github_service import (
    get_issue_events,
    list_issues_by_label,
    update_issue_labels,
)

logger = logging.getLogger(__name__)


class ScrumMasterService:
    def __init__(self):
        self.sprint_duration_days = 14  # 2 weeks cycle
        self.work_days_in_sprint = 10

    def calculate_team_velocity(self) -> int:
        """
        Calcula a velocidade média do time baseada no histórico.
        TODO: Implementar consulta real ao histórico de sprints fechadas.
        """
        return 100  # Mock value for now

    async def plan_next_sprint(self) -> Sprint:
        """
        Planeja a próxima sprint priorizando itens críticos (SLA) e preenchendo capacidade.
        """
        logger.info("Iniciando planejamento da Sprint...")

        # 1. Definir datas
        start_date = datetime.now()
        end_date = start_date + timedelta(days=self.sprint_duration_days)

        sprint_id = f"{start_date.year}-S{start_date.strftime('%U')}"

        # 2. Obter capacidade
        capacity = self.calculate_team_velocity()
        remaining_capacity = capacity
        selected_issues = []

        # 3. Buscar backlog (status:aguardando-liberacao-dev)
        backlog_issues = await list_issues_by_label("status:aguardando-liberacao-dev")

        logger.info(f"Backlog encontrado: {len(backlog_issues)} issues.")

        critical_backlog = []
        standard_backlog = []

        # 4. Classificar issues
        for issue in backlog_issues:
            labels = issue.get("labels", [])
            is_critical = any(label in CRITICAL_SLA_TYPES for label in labels)

            # Estimativa de esforço (PF)
            estimated_pf = 5

            issue_data = {
                "id": issue["number"],
                "title": issue["title"],
                "labels": labels,
                "pf": estimated_pf,
                "is_critical": is_critical,
            }

            if is_critical:
                critical_backlog.append(issue_data)
            else:
                standard_backlog.append(issue_data)

        # 5. Priorização 1: Críticos (Fura-Fila)
        logger.info(f"Processando {len(critical_backlog)} issues críticas...")
        for item in critical_backlog:
            selected_issues.append(item)
            remaining_capacity -= item["pf"]

        # 6. Priorização 2: Preenchimento com Standard
        logger.info(
            f"Capacidade restante: {remaining_capacity}. Processando {len(standard_backlog)} issues padrão..."
        )
        for item in standard_backlog:
            if remaining_capacity >= item["pf"]:
                selected_issues.append(item)
                remaining_capacity -= item["pf"]
            else:
                continue

        # 7. Ação: Aplicar label sprint:atual
        selected_ids = [item["id"] for item in selected_issues]
        logger.info(f"Issues selecionadas para a Sprint {sprint_id}: {selected_ids}")

        for issue_id in selected_ids:
            try:
                await update_issue_labels(issue_id, add_labels=["sprint:atual"])
            except Exception as e:
                logger.error(f"Erro ao atualizar label da issue {issue_id}: {e}")

        # 8. Criar objeto Sprint
        sprint = Sprint(
            id=sprint_id,
            start_date=start_date,
            end_date=end_date,
            status=SprintStatus.PLANNING,
            planned_capacity_pf=capacity,
            issue_ids=selected_ids,
        )

        # 9. Persistência (Mock)
        self._save_sprint(sprint)

        logger.info(
            f"Sprint {sprint_id} planejada com sucesso. {len(selected_issues)} issues incluídas."
        )
        return sprint

    def _save_sprint(self, sprint: Sprint):
        sprint_json = sprint.json()
        logger.info(f"PERSISTENCIA SPRINT: {sprint_json}")
        try:
            with open(f"data/sprint_{sprint.id}.json", "w") as f:
                f.write(sprint_json)
        except Exception as e:
            logger.warning(f"Não foi possível salvar arquivo de sprint: {e}")

    async def monitor_active_sprint_issues(self, critical_only: bool = False) -> dict:
        """
        Monitora issues ativas na sprint para detectar riscos de SLA e bloqueios.
        Args:
            critical_only (bool): Se True, verifica apenas issues críticas (Garantia/Corretiva).
        """
        logger.info(
            f"Iniciando monitoramento de Sprint (Critical Only: {critical_only})..."
        )

        # 1. Buscar issues da sprint atual
        # Como list_issues_by_label filtra por UMA label, e precisamos de 'sprint:atual', ok.
        active_issues = await list_issues_by_label("sprint:atual")

        actions_taken = {
            "checked": 0,
            "sla_warning": 0,
            "sla_breached": 0,
            "qa_loop": 0,
        }

        for issue in active_issues:
            issue_number = issue["number"]
            labels = issue.get("labels", [])

            # Filtro para critical_only
            is_critical = any(label in CRITICAL_SLA_TYPES for label in labels)
            if critical_only and not is_critical:
                continue

            actions_taken["checked"] += 1

            # 2. Determinar SLA
            sla_hours = 80  # Default (RCM/Migração)
            for label, hours in ISSUE_SLA_HOURS.items():
                if label in labels:
                    sla_hours = hours
                    break

            # 3. Calcular Tempo Decorrido
            # Busca eventos para saber quando entrou em progresso (saiu de aguardando-liberacao-dev)
            events = await get_issue_events(issue_number)
            start_time = None

            # Procura o evento 'unlabeled' de 'status:aguardando-liberacao-dev' mais recente
            # Ou 'labeled' de 'sprint:atual'
            for event in reversed(events):
                if event["event"] == "labeled" and event["label"] == "sprint:atual":
                    start_time = datetime.fromisoformat(event["created_at"])
                    break

            if not start_time:
                # Fallback: created_at se não achar evento (assumindo que entrou logo)
                start_time = datetime.fromisoformat(issue["created_at"])

            elapsed_time = datetime.now(start_time.tzinfo) - start_time
            elapsed_hours = elapsed_time.total_seconds() / 3600

            # 4. Regra de Risco SLA
            risk_labels_to_add = []

            if elapsed_hours > sla_hours:
                # Estourado (> 100%)
                if "risco:sla-estourado" not in labels:
                    risk_labels_to_add.append("risco:sla-estourado")
                    actions_taken["sla_breached"] += 1
                    await add_alert(
                        f"SLA ESTOURADO: Issue #{issue_number} ({issue['title']}) excedeu {sla_hours}h (está em {elapsed_hours:.1f}h).",
                        category="sla_breach",
                        issue_number=issue_number,
                        severity="high",
                    )
            elif elapsed_hours > (sla_hours * 0.8):
                # Iminente (> 80%)
                if "risco:sla-iminente" not in labels:
                    risk_labels_to_add.append("risco:sla-iminente")
                    actions_taken["sla_warning"] += 1

            # 5. Regra de Bloqueio (Loop QA)
            # Conta quantas vezes recebeu a label 'status:aguardando-correcao-doc'
            qa_rejections = sum(
                1
                for e in events
                if e["event"] == "labeled"
                and e["label"] == "status:aguardando-correcao-doc"
            )

            if qa_rejections > 2:
                if "bloqueado:loop-qa" not in labels:
                    risk_labels_to_add.append("bloqueado:loop-qa")
                    actions_taken["qa_loop"] += 1
                    await add_alert(
                        f"BLOQUEIO DETECTADO: Issue #{issue_number} está em Loop de QA ({qa_rejections} rejeições).",
                        category="process_block",
                        issue_number=issue_number,
                        severity="critical",
                    )

            # Aplicar labels se necessário
            if risk_labels_to_add:
                await update_issue_labels(issue_number, add_labels=risk_labels_to_add)
                logger.info(
                    f"Issue #{issue_number}: Aplicadas labels de risco {risk_labels_to_add}"
                )

        logger.info(f"Monitoramento concluído. Resumo: {actions_taken}")
        return actions_taken

    async def get_current_sprint_stats(self) -> dict:
        """
        Retorna estatísticas da sprint atual.
        """
        active_issues = await list_issues_by_label("sprint:atual")

        total_pf = 0
        completed_pf = 0
        issues_done = 0
        issues_at_risk = 0

        issues_data = []

        for issue in active_issues:
            # Estimate PF (mock 5 if not found)
            pf = 5  # TODO: Extract from body
            total_pf += pf

            if issue.get("state") == "closed":
                completed_pf += pf
                issues_done += 1

            labels = issue.get("labels", [])
            if "risco:sla-iminente" in labels or "risco:sla-estourado" in labels:
                issues_at_risk += 1

            issues_data.append(
                {
                    "id": issue["number"],
                    "title": issue["title"],
                    "status": "done"
                    if issue.get("state") == "closed"
                    else "todo",  # Simplification, need better mapping
                    "labels": labels,
                    "pf": pf,
                    "assignee": issue.get("assignee", {}).get("login")
                    if issue.get("assignee")
                    else None,
                }
            )

        # Mock dates if no sprint file loaded (Simulação)
        start_date = datetime.now() - timedelta(days=2)  # Mock: started 2 days ago
        end_date = start_date + timedelta(days=14)

        return {
            "id": f"{start_date.year}-S{start_date.strftime('%U')}",
            "start_date": start_date.isoformat(),
            "end_date": end_date.isoformat(),
            "total_pf": total_pf,
            "completed_pf": completed_pf,
            "issues_total": len(active_issues),
            "issues_done": issues_done,
            "issues_at_risk": issues_at_risk,
            "issues_data": issues_data,
        }

    async def take_daily_snapshot(self) -> SprintSnapshot:
        """
        Tira um snapshot do estado atual da sprint e salva no histórico.
        """
        logger.info("Executando Snapshot Diário da Sprint...")
        stats = await self.get_current_sprint_stats()
        sprint_id = stats["id"]

        snapshot = SprintSnapshot(
            sprint_id=sprint_id,
            date=datetime.now(),
            remaining_pf=stats["total_pf"] - stats["completed_pf"],
            completed_pf=stats["completed_pf"],
        )

        history_file = f"data/sprint_history_{sprint_id}.json"
        history = []

        if os.path.exists(history_file):
            try:
                with open(history_file, "r") as f:
                    data = json.load(f)
                    history = [SprintSnapshot(**item) for item in data]
            except Exception as e:
                logger.error(f"Erro ao ler histórico da sprint {sprint_id}: {e}")

        # Adicionar novo snapshot
        history.append(snapshot)

        # Salvar
        try:
            with open(history_file, "w") as f:
                json.dump([s.dict() for s in history], f, default=str, indent=2)
            logger.info(f"Snapshot salvo para sprint {sprint_id}.")
        except Exception as e:
            logger.error(f"Erro ao salvar snapshot: {e}")

        return snapshot

    async def get_burndown_data(self) -> list[dict]:
        """
        Retorna dados para o gráfico de Burndown (Histórico Real vs Ideal).
        """
        stats = await self.get_current_sprint_stats()
        sprint_id = stats["id"]
        total_pf = stats["total_pf"]
        start_date = datetime.fromisoformat(stats["start_date"])

        data = []
        history_file = f"data/sprint_history_{sprint_id}.json"
        snapshots = []

        # Tentar carregar histórico real
        if os.path.exists(history_file):
            try:
                with open(history_file, "r") as f:
                    raw_data = json.load(f)
                    snapshots = [SprintSnapshot(**item) for item in raw_data]
            except Exception as e:
                logger.error(f"Erro ao ler histórico para burndown: {e}")

        # Gerar gráfico
        for i in range(15):  # 14 dias + 1
            day = start_date + timedelta(days=i)
            day_str = day.strftime("%Y-%m-%d")

            # Ideal Line
            ideal = total_pf - (total_pf / 14) * i

            # Actual Line (Find snapshot for this day)
            actual = None

            # Procura snapshot do dia (ou mais próximo do fim do dia)
            daily_snaps = [s for s in snapshots if s.date.date() == day.date()]
            if daily_snaps:
                # Pega o último snapshot do dia
                last_snap = daily_snaps[-1]
                actual = last_snap.remaining_pf
            elif i == 0:
                # Dia 0 começa com total
                actual = total_pf

            # Se não tem snapshot e o dia já passou, mantém o último valor conhecido (ou null se preferir buraco)
            # Aqui vamos deixar null para não plotar linha futura, mas preencher dias passados sem snapshot com o anterior
            if actual is None and day <= datetime.now():
                # Tenta pegar o último valor válido da lista data
                if data and data[-1]["actual"] is not None:
                    actual = data[-1]["actual"]

            data.append(
                {"day": day_str, "ideal": round(max(0, ideal), 1), "actual": actual}
            )

        return data

    async def close_current_sprint(self) -> SprintReport:
        """
        Fecha a sprint atual, gera relatório e remove labels de spilled issues.
        """
        logger.info("Iniciando fechamento de Sprint...")
        stats = await self.get_current_sprint_stats()

        sprint_id = stats["id"]
        total_pf = stats["total_pf"]
        delivered_pf = stats["completed_pf"]

        # Calcular métricas
        velocity = (delivered_pf / total_pf * 100) if total_pf > 0 else 0

        # Spilled Issues (Não entregues)
        spilled_issues = [i for i in stats["issues_data"] if i["status"] != "done"]
        spilled_count = len(spilled_issues)

        # Blocker Count (Issues com label 'bloqueado:loop-qa' ou similar)
        blocker_count = sum(
            1
            for i in stats["issues_data"]
            if any("bloqueado" in l for l in i["labels"])
        )

        # Ação: Remover label sprint:atual das spilled
        for issue in spilled_issues:
            try:
                await update_issue_labels(issue["id"], remove_labels=["sprint:atual"])
                logger.info(f"Issue #{issue['id']} removida da sprint (Spilled).")
            except Exception as e:
                logger.error(f"Erro ao remover label da issue {issue['id']}: {e}")

        # Criar Relatório
        report = SprintReport(
            sprint_id=sprint_id,
            close_date=datetime.now(),
            planned_pf=total_pf,
            delivered_pf=delivered_pf,
            velocity_achieved=round(velocity, 2),
            average_lead_time_days=0.0,  # TODO: Implementar cálculo real
            spilled_issues_count=spilled_count,
            blocker_count=blocker_count,
        )

        # Salvar Relatório
        try:
            with open(f"data/report_{sprint_id}.json", "w") as f:
                f.write(report.json())
            logger.info(f"Relatório da Sprint {sprint_id} salvo com sucesso.")
        except Exception as e:
            logger.error(f"Erro ao salvar relatório: {e}")
            raise e

        return report

    async def get_all_reports(self) -> List[SprintReport]:
        reports = []
        files = glob.glob("data/report_*.json")
        for fpath in files:
            try:
                with open(fpath, "r") as f:
                    data = json.load(f)
                    reports.append(SprintReport(**data))
            except Exception as e:
                logger.error(f"Erro ao ler relatório {fpath}: {e}")

        # Ordenar por data (recente primeiro)
        reports.sort(key=lambda x: x.close_date, reverse=True)
        return reports

    async def get_report_by_id(self, sprint_id: str) -> SprintReport:
        try:
            with open(f"data/report_{sprint_id}.json", "r") as f:
                data = json.load(f)
                return SprintReport(**data)
        except FileNotFoundError:
            return None


# Instância global
scrum_master_service = ScrumMasterService()

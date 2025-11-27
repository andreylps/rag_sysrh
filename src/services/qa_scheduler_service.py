import json
import logging
import os
import uuid
from datetime import datetime, timedelta

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.date import DateTrigger

from src.models.qa_models import AuditSchedule

# Configuração de Logging
logger = logging.getLogger(__name__)

# Arquivo de persistência simples para agendamentos (JSON)
SCHEDULE_FILE = "data/qa_schedule.json"


class QASchedulerService:
    def __init__(self):
        self.scheduler = AsyncIOScheduler()
        self.scheduler_started = False
        self._ensure_schedule_file()

    def _ensure_schedule_file(self):
        if not os.path.exists(SCHEDULE_FILE):
            with open(SCHEDULE_FILE, "w") as f:
                json.dump([], f)

    def _load_schedules(self):
        try:
            with open(SCHEDULE_FILE, "r") as f:
                data = json.load(f)
                return [AuditSchedule(**item) for item in data]
        except Exception as e:
            logger.error(f"Erro ao carregar agendamentos: {e}")
            return []

    def _save_schedule(self, schedule: AuditSchedule):
        schedules = self._load_schedules()

        # Check if exists and update, otherwise append
        existing_index = next(
            (i for i, s in enumerate(schedules) if s.id == schedule.id), -1
        )

        if existing_index >= 0:
            schedules[existing_index] = schedule
        else:
            schedules.append(schedule)

        with open(SCHEDULE_FILE, "w") as f:
            json.dump([s.dict() for s in schedules], f, default=str)

    def start(self):
        if not self.scheduler_started:
            self.scheduler.start()
            self.scheduler_started = True
            logger.info("QA Scheduler iniciado.")

            # Reagendar tarefas persistidas
            schedules = self._load_schedules()
            pending_count = 0
            recovered_count = 0

            for schedule in schedules:
                # Recuperar jobs que estavam rodando quando o servidor parou (Crash Recovery)
                if schedule.status == "RUNNING":
                    logger.warning(
                        f"Recuperando job interrompido: {schedule.id} ({schedule.audit_type})"
                    )
                    schedule.status = "PENDING"
                    self._save_schedule(schedule)
                    recovered_count += 1

                if schedule.status == "PENDING":
                    # Se a data já passou, o APScheduler vai executar imediatamente (se grace time permitir)
                    # ou podemos forçar. Vamos deixar o APScheduler lidar com isso.
                    self.scheduler.add_job(
                        self._execute_audit_job,
                        trigger=DateTrigger(run_date=schedule.scheduled_date),
                        args=[schedule.id],
                        id=schedule.id,
                        replace_existing=True,
                        misfire_grace_time=None,  # Executa mesmo se atrasado
                    )
                    pending_count += 1

            logger.info(
                f"Reagendados {pending_count} jobs pendentes (Recuperados de crash: {recovered_count})."
            )

            # Se não houver nada agendado (nem pendente nem concluído/falho que indicaria histórico),
            # ou se quisermos forçar planejamento se não houver FUTUROS?
            # A lógica original era "se lista vazia". Vamos manter.
            # Verificar se existem agendamentos futuros
            future_schedules = [
                s for s in schedules if s.scheduled_date > datetime.now()
            ]

            if not future_schedules:
                logger.info(
                    "Nenhum agendamento futuro encontrado. Iniciando planejamento trimestral automático."
                )
                self.plan_quarterly_schedule()

    def plan_quarterly_schedule(self, start_date: datetime = None):
        """Planeja auditorias para o próximo trimestre com frequências específicas."""
        if not start_date:
            start_date = datetime.now()

        logger.info(
            f"Planejando auditorias trimestrais (Regras Estritas) a partir de {start_date}"
        )

        # Limpar agendamentos futuros para evitar duplicatas ao replanejar
        self._clear_future_schedules(start_date)

        end_date = start_date + timedelta(days=90)

        # Definir horário padrão para 08:00 AM
        current_date = start_date.replace(hour=8, minute=0, second=0, microsecond=0)

        # Se start_date for hoje e já passou das 8h, agendar para agora + 5 min ou próximo dia?
        # Se for passado, o _schedule_audit vai ignorar se for > 1h atrás.
        # Vamos garantir que se for hoje e já passou das 8h, agendamos para "agora" ou ignoramos o dia?
        # Melhor: Se current_date < now, ajusta para now + 1 min (apenas para o dia inicial)
        if current_date < datetime.now():
            # Se for o dia de hoje, ajusta para agora. Se for dia passado, o loop vai tratar.
            if current_date.date() == datetime.now().date():
                current_date = datetime.now() + timedelta(minutes=1)

        # Contadores para frequências relativas (apenas dias úteis)
        business_day_counter = 0

        # Sprint Audit: a cada 9 dias úteis
        # Doc: 15 dias úteis
        # Software: 5 dias úteis
        # Code Review: 2 dias úteis
        # Diária: Todo dia útil

        while current_date <= end_date:
            is_weekend = current_date.weekday() >= 5

            # Pular fins de semana completamente
            if is_weekend:
                current_date += timedelta(days=1)
                continue

            # Se é dia útil, incrementa contador (começando de 0 ou 1? Vamos usar 0-based index para modulos)
            # Mas queremos que o dia 0 (hoje) conte? Sim.

            # 1. Auditorias Diárias (Daily Checks) - Apenas dias úteis
            self._schedule_audit(current_date, "DAILY_CHECK", {"type": "Rotina"})

            # 2. Code Review (A cada 2 dias úteis)
            if business_day_counter % 2 == 0:
                self._schedule_audit(
                    current_date, "CODEREVIEW_AUDIT", {"focus": "Pull Requests"}
                )

            # 3. Software Audit (A cada 5 dias úteis)
            if business_day_counter % 5 == 0:
                self._schedule_audit(
                    current_date, "CODE_AUDIT", {"focus": "Padrões de Projeto"}
                )

            # 4. Auditoria de Documentação (A cada 15 dias úteis)
            if business_day_counter % 15 == 0:
                self._schedule_audit(current_date, "DOC_AUDIT", {"focus": "ISO 9001"})

            # 5. Auditoria de Sprint (A cada 9 dias úteis)
            # Evitar dia 0 se quiser, mas "a cada 9" implica 0, 9, 18...
            # Se o usuário quer "daqui a 9 dias", seria business_day_counter > 0.
            # Vou assumir intervalos regulares incluindo o start point ou start + 9.
            # Geralmente sprint review é no fim. Vamos colocar start + 9.
            if business_day_counter > 0 and business_day_counter % 9 == 0:
                self._schedule_audit(
                    current_date, "SPRINT_AUDIT", {"focus": "Entregas da Sprint"}
                )

            current_date += timedelta(days=1)
            # Garantir que os próximos dias sejam às 08:00 AM
            current_date = current_date.replace(
                hour=8, minute=0, second=0, microsecond=0
            )
            business_day_counter += 1

        # 6. Auditoria Trimestral (No final - garantir que caia em dia útil?)
        # Se cair fds, ajusta para sexta anterior ou segunda seguinte.
        while end_date.weekday() >= 5:
            end_date -= timedelta(days=1)

        self._schedule_audit(
            end_date,
            "QUARTERLY_REPORT",
            {"period_start": start_date, "period_end": end_date},
        )

    def _clear_future_schedules(self, start_date: datetime):
        """Remove agendamentos futuros a partir da data de início para evitar duplicatas."""
        schedules = self._load_schedules()
        # Manter passados e remover futuros (>= start_date) que ainda estão PENDING
        # Ou remover tudo >= start_date independente do status? Melhor preservar o histórico.
        # Vamos remover apenas PENDING >= start_date

        kept_schedules = [
            s
            for s in schedules
            if s.scheduled_date < start_date or s.status != "PENDING"
        ]

        # Salvar
        with open(SCHEDULE_FILE, "w") as f:
            json.dump([s.dict() for s in kept_schedules], f, default=str)

        logger.info(f"Agendamentos futuros limpos a partir de {start_date}")

    def _schedule_audit(self, audit_date: datetime, audit_type: str, details: dict):
        # Evitar agendar no passado se start_date for hoje
        if audit_date < datetime.now() - timedelta(hours=1):
            return

        # Verificar se já existe agendamento do mesmo tipo para o mesmo dia (evitar duplicatas)
        schedules = self._load_schedules()
        existing = next(
            (
                s
                for s in schedules
                if s.audit_type == audit_type
                and s.scheduled_date.date() == audit_date.date()
                and s.status in ["PENDING", "COMPLETED", "RUNNING"]
            ),
            None,
        )

        if existing:
            # logger.info(f"Pulo: Já existe {audit_type} para {audit_date.date()}")
            return

        schedule_id = str(uuid.uuid4())
        audit_schedule = AuditSchedule(
            id=schedule_id,
            scheduled_date=audit_date,
            audit_type=audit_type,
            status="PENDING",
            details=details,
        )
        self._save_schedule(audit_schedule)

        # Adicionar job apenas se for futuro próximo (para não sobrecarregar scheduler) ou adicionar todos
        # O APScheduler lida bem com muitos jobs.
        self.scheduler.add_job(
            self._execute_audit_job,
            trigger=DateTrigger(run_date=audit_date),
            args=[schedule_id],
            id=schedule_id,
            replace_existing=True,
        )
        # Logger reduzido para não spammar
        # logger.info(f"Agendado: {audit_type} para {audit_date}")

    async def _execute_audit_job(self, schedule_id: str):
        """Callback executado pelo APScheduler."""
        logger.info(f"Executando auditoria agendada: {schedule_id}")
        from src.services.audit_service import audit_service
        from src.services.knowledge_feedback_service import knowledge_feedback_service

        schedules = self._load_schedules()
        schedule = next((s for s in schedules if s.id == schedule_id), None)

        if schedule:
            # Atualizar status para RUNNING (poderia persistir aqui)
            schedule.status = "RUNNING"
            self._save_schedule(schedule)  # Salva estado running

            try:
                if schedule.audit_type == "SPRINT_AUDIT":
                    cycle_start = schedule.details.get("cycle_start")
                    if isinstance(cycle_start, str):
                        cycle_start = datetime.fromisoformat(cycle_start)
                    await audit_service.execute_sprint_end_audit(
                        cycle_start, datetime.now()
                    )

                elif schedule.audit_type == "QUARTERLY_REPORT":
                    period_start = schedule.details.get("period_start")
                    period_end = schedule.details.get("period_end")
                    # Converter strings se necessário
                    if isinstance(period_start, str):
                        period_start = datetime.fromisoformat(period_start)
                    if isinstance(period_end, str):
                        period_end = datetime.fromisoformat(period_end)

                    await audit_service.generate_quarterly_report(
                        period_start, period_end
                    )

                else:
                    # Outros tipos (DOC, CODE, SECURITY) - Implementação genérica por enquanto
                    logger.info(
                        f"Executando auditoria específica: {schedule.audit_type}"
                    )
                    # Simula execução
                    await audit_service.execute_generic_audit(
                        schedule.audit_type, schedule.details
                    )

                # Feedback Loop (Fase 7.1)
                try:
                    knowledge_feedback_service.process_latest_pdca_report()
                except Exception as e:
                    logger.error(f"Erro no feedback loop: {e}")

                schedule.status = "COMPLETED"

            except Exception as e:
                logger.error(f"Falha na auditoria {schedule_id}: {e}")
                schedule.status = "FAILED"

            self._save_schedule(schedule)  # Salva estado final

    async def _autonomous_decision_job(self):
        """Decide se deve agendar um Spot Check."""
        # ... (manter lógica existente ou aprimorar)
        pass

    def get_upcoming_audits(self):
        """Retorna agendamentos futuros."""
        schedules = self._load_schedules()
        return sorted(
            [s for s in schedules if s.status in ["PENDING", "RUNNING"]],
            key=lambda x: x.scheduled_date,
        )

    def get_all_schedules(self):
        """Retorna todos os agendamentos (passados e futuros)."""
        schedules = self._load_schedules()
        return sorted(schedules, key=lambda x: x.scheduled_date)

    def get_schedule_stats(self):
        """Retorna estatísticas dos agendamentos."""
        schedules = self._load_schedules()
        total = len(schedules)
        pending = sum(1 for s in schedules if s.status == "PENDING")
        completed = sum(1 for s in schedules if s.status == "COMPLETED")
        failed = sum(1 for s in schedules if s.status == "FAILED")

        # Contagem por tipo (apenas futuros/recentes ou total?)
        # Vamos fazer total por tipo
        by_type = {}
        for s in schedules:
            by_type[s.audit_type] = by_type.get(s.audit_type, 0) + 1

        return {
            "total": total,
            "pending": pending,
            "completed": completed,
            "failed": failed,
            "by_type": by_type,
        }


qa_scheduler = QASchedulerService()

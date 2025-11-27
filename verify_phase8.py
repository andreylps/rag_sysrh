import os
import sys
from datetime import datetime

# Adiciona o diretório raiz ao path
sys.path.append(os.getcwd())

from src.services.qa_scheduler_service import qa_scheduler


def verify_phase8():
    print("1. Limpando agendamentos antigos...")
    if os.path.exists("data/qa_schedule.json"):
        os.remove("data/qa_schedule.json")
    qa_scheduler._ensure_schedule_file()

    print("2. Executando Planejamento Trimestral...")
    start_date = datetime.now()
    qa_scheduler.plan_quarterly_schedule(start_date)

    print("3. Verificando Agendamentos...")
    schedules = qa_scheduler.get_upcoming_audits()

    print(f"Total de agendamentos: {len(schedules)}")

    sprint_audits = [s for s in schedules if s.audit_type == "SPRINT_AUDIT"]
    doc_audits = [s for s in schedules if s.audit_type == "DOC_AUDIT"]
    code_audits = [s for s in schedules if s.audit_type == "CODE_AUDIT"]
    codereview_audits = [s for s in schedules if s.audit_type == "CODEREVIEW_AUDIT"]
    daily_audits = [s for s in schedules if s.audit_type == "DAILY_CHECK"]
    quarterly_reports = [s for s in schedules if s.audit_type == "QUARTERLY_REPORT"]

    print(f"Sprint Audits: {len(sprint_audits)} (Esperado: ~6)")
    print(f"Doc Audits: {len(doc_audits)} (Esperado: ~4)")
    print(f"Code Audits (5 dias): {len(code_audits)} (Esperado: ~13)")
    print(f"Code Review (2 dias): {len(codereview_audits)} (Esperado: ~32)")
    print(f"Daily Audits: {len(daily_audits)} (Esperado: ~65)")
    print(f"Quarterly Reports: {len(quarterly_reports)} (Esperado: 1)")

    if len(daily_audits) >= 60 and len(quarterly_reports) == 1:
        print("✅ Planejamento Trimestral OK!")

        # Verificar se hoje (Day 0) tem auditorias
        today_str = start_date.strftime("%Y-%m-%d")
        today_audits = [
            s for s in schedules if s.scheduled_date.strftime("%Y-%m-%d") == today_str
        ]
        print(f"Auditorias Hoje ({today_str}): {len(today_audits)}")
        for a in today_audits:
            print(f" - {a.audit_type}")

        if len(today_audits) >= 4:
            print("✅ Auditorias de hoje populadas corretamente.")
        else:
            print("❌ Falha: Auditorias de hoje ausentes.")

        # Verificar regra do 9º dia (aprox 11 dias)
        first_sprint = sprint_audits[0]
        days_diff = (first_sprint.scheduled_date - start_date).days
        print(
            f"Primeira Sprint Audit agendada para {days_diff} dias após o início (Esperado ~11)."
        )

        # Verificar se há duplicatas (mesmo tipo no mesmo dia)
        seen = set()
        duplicates = []
        for s in schedules:
            key = (s.scheduled_date.strftime("%Y-%m-%d"), s.audit_type)
            if key in seen:
                duplicates.append(key)
            seen.add(key)

        if duplicates:
            print(f"❌ Duplicatas encontradas: {len(duplicates)}")
            for d in duplicates[:5]:
                print(f" - {d}")
        else:
            print("✅ Sem duplicatas.")

        # Verificar se há agendamentos em finais de semana
        weekend_audits = [s for s in schedules if s.scheduled_date.weekday() >= 5]
        if weekend_audits:
            print(f"❌ Auditorias em fim de semana: {len(weekend_audits)}")
            for w in weekend_audits[:5]:
                print(f" - {w.audit_type} em {w.scheduled_date}")
        else:
            print("✅ Sem auditorias em fim de semana.")

    else:
        print("❌ Falha no Planejamento.")


if __name__ == "__main__":
    verify_phase8()

from datetime import datetime, timedelta
from typing import List

from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse

from src.models.qa_models import AuditSchedule, PDCAReport
from src.services.audit_service import execute_sprint_end_audit, get_all_reports
from src.services.qa_scheduler_service import qa_scheduler

router = APIRouter()


@router.get("/schedule", response_model=List[AuditSchedule])
async def get_schedule():
    """Retorna a agenda de auditorias futuras."""
    return qa_scheduler.get_upcoming_audits()


@router.get("/reports", response_model=List[PDCAReport])
async def get_reports():
    """Retorna o histórico de relatórios PDCA."""
    return get_all_reports()


@router.get("/reports/{report_id}/download")
async def download_report(report_id: str):
    """Baixa o PDF de um relatório específico."""
    reports = get_all_reports()
    report = next((r for r in reports if r.id == report_id), None)

    if not report:
        raise HTTPException(status_code=404, detail="Relatório não encontrado")

    # Garantir caminho absoluto e normalizado
    import os

    file_path = os.path.abspath(report.pdf_file_path)

    if not os.path.exists(file_path):
        raise HTTPException(
            status_code=404, detail=f"Arquivo PDF não encontrado em: {file_path}"
        )

    return FileResponse(
        file_path,
        media_type="application/pdf",
        filename=f"PDCA_{report.cycle_period.replace(' ', '_').replace('/', '-')}.pdf",
    )


@router.post("/trigger-sprint")
async def trigger_sprint_audit():
    """
    Gatilho manual para testar a Auditoria de Sprint.
    Simula uma sprint que terminou hoje, começando 10 dias atrás.
    """
    end_date = datetime.now()
    start_date = end_date - timedelta(days=14)  # 2 semanas aprox

    try:
        report = await execute_sprint_end_audit(start_date, end_date)
        return {
            "status": "success",
            "report_id": report.id,
            "message": "Auditoria executada com sucesso.",
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/plan-quarterly")
async def plan_quarterly():
    """
    Planeja automaticamente as auditorias para o próximo trimestre.
    """
    try:
        qa_scheduler.plan_quarterly_schedule()
        return {
            "status": "success",
            "message": "Planejamento trimestral gerado com sucesso.",
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

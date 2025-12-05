from fastapi import APIRouter, HTTPException

from src.services.scrum_master_service import scrum_master_service

router = APIRouter()


@router.get("/current-sprint")
async def get_current_sprint():
    """
    Retorna o resumo da sprint ativa.
    """
    try:
        return await scrum_master_service.get_current_sprint_stats()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/burndown-data")
async def get_burndown_data():
    """
    Retorna os dados para o gráfico de Burndown.
    """
    try:
        return await scrum_master_service.get_burndown_data()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/reports")
async def get_reports():
    """
    Retorna lista de relatórios de sprints fechadas.
    """
    try:
        return await scrum_master_service.get_all_reports()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/reports/{sprint_id}")
async def get_report_detail(sprint_id: str):
    """
    Retorna detalhes de um relatório específico.
    """
    report = await scrum_master_service.get_report_by_id(sprint_id)
    if not report:
        raise HTTPException(status_code=404, detail="Relatório não encontrado")
    return report


@router.get("/dashboard")
async def get_scrum_dashboard():
    """
    Retorna todas as métricas avançadas para a Sala Scrum.
    """
    try:
        return await scrum_master_service.calculate_advanced_metrics()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/agent/report")
async def generate_scrum_report(
    report_type: str,  # review, retro, planning
    sprint_id: str = None,
):
    """
    Gera um relatório qualitativo usando o Agente Scrum (IA).
    """
    try:
        from src.agents.scrum_agent import scrum_agent

        report = await scrum_agent.generate_report(report_type, sprint_id)
        return {"report": report}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/close-sprint")
async def close_sprint():
    """
    Força o fechamento da sprint atual (Manual Trigger).
    """
    try:
        return await scrum_master_service.close_current_sprint()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/force-monitor")
async def force_monitor_sprint(critical_only: bool = False):
    """
    Força a execução do monitoramento de riscos da sprint.
    """
    try:
        return await scrum_master_service.monitor_active_sprint_issues(
            critical_only=critical_only
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

from datetime import datetime
from typing import Any, Dict

from pydantic import BaseModel, Field


class AuditSchedule(BaseModel):
    """Modelo para agendamento de auditorias."""

    id: str
    scheduled_date: datetime
    audit_type: str  # 'SPRINT_AUDIT', 'DOC_AUDIT', 'CODE_AUDIT', 'SECURITY_AUDIT', 'CODEREVIEW_AUDIT', 'QUARTERLY_REPORT'
    status: str = "PENDING"  # 'PENDING', 'RUNNING', 'COMPLETED', 'CANCELLED'
    details: Dict[str, Any] = Field(default_factory=dict)  # Critérios ISO alvo, etc.
    created_at: datetime = Field(default_factory=datetime.now)


class PDCAReport(BaseModel):
    """Modelo para relatórios PDCA históricos."""

    id: str
    generation_date: datetime
    cycle_period: str  # Ex: 'Sprint 15 - Nov/2025'
    summary: str
    pdf_file_path: str
    metrics_snapshot: Dict[str, Any] = Field(default_factory=dict)
    audit_type: str
    improvement_suggestion: str = "Nenhuma sugestão registrada."

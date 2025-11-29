# src/schemas/sprint.py
from datetime import datetime
from enum import Enum
from typing import List

from pydantic import BaseModel, Field


class SprintStatus(str, Enum):
    PLANNING = "PLANNING"
    ACTIVE = "ACTIVE"
    CLOSED = "CLOSED"


class Sprint(BaseModel):
    id: str  # Format: 'YYYY-S##' e.g., '2025-S01'
    start_date: datetime
    end_date: datetime
    status: SprintStatus = SprintStatus.PLANNING
    planned_capacity_pf: int = Field(
        ..., description="Pontos de Função planejados para a sprint"
    )
    issue_ids: List[int] = Field(
        default_factory=list, description="Lista dos IDs das issues incluídas na sprint"
    )

    class Config:
        use_enum_values = True


class SprintReport(BaseModel):
    sprint_id: str
    close_date: datetime
    planned_pf: int
    delivered_pf: int
    velocity_achieved: float = Field(
        ..., description="Percentual de velocidade atingida"
    )
    average_lead_time_days: float
    spilled_issues_count: int
    blocker_count: int

    class Config:
        use_enum_values = True


class SprintSnapshot(BaseModel):
    sprint_id: str
    date: datetime
    remaining_pf: int
    completed_pf: int

    class Config:
        use_enum_values = True

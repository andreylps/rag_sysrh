from enum import Enum
from typing import Optional

from pydantic import BaseModel, validator


class ClientActionEnum(str, Enum):
    APPROVE = "approve"
    REJECT = "reject"


class RCMApprovalDTO(BaseModel):
    final_rcm_text: str
    analyst_comments: Optional[str] = None
    client_email: Optional[str] = None  # Novo campo para envio de notificação


class ClientActionDTO(BaseModel):
    action: ClientActionEnum
    client_comments: Optional[str] = None

    @validator("client_comments")
    def check_comments_if_rejected(cls, v, values):
        action = values.get("action")
        if action == ClientActionEnum.REJECT and not v:
            raise ValueError("Comentários são obrigatórios em caso de rejeição.")
        return v


class HistoryItemDTO(BaseModel):
    date: str
    user: str
    action: str  # "Aprovado pelo Analista", "Rejeitado pelo Cliente", etc.
    comments: Optional[str] = None


class RCMDetailsDTO(BaseModel):
    issue_number: int
    title: str
    status: str
    # Métricas para o Dashboard
    pontos_funcao: float
    prazo_dias: int
    custo_total: float  # Placeholder para valor monetário se houver
    # Conteúdo
    rcm_text: str
    # Histórico
    history: list[HistoryItemDTO]

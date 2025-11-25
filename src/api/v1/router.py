# src/api/v1/router.py

from fastapi import APIRouter

# Importa todos os endpoints, INCLUINDO O DASHBOARD
from src.api.v1.endpoints import (
    admin,  # <--- Novo endpoint
    chat,
    dashboard,
    knowledge,
    solicitacoes,
    validacao,
)

api_router = APIRouter()

# --- REGISTRO DAS ROTAS ---

# Rota do Dashboard (RECONECTADA)
api_router.include_router(dashboard.router, prefix="/dashboard", tags=["dashboard"])

# Rota de Solicitações
api_router.include_router(
    solicitacoes.router, prefix="/solicitacoes", tags=["solicitações"]
)

# Rota da Base de Conhecimento
api_router.include_router(
    knowledge.router, prefix="/knowledge", tags=["knowledge-base"]
)

# Rota de Validação (que adicionamos recentemente)
api_router.include_router(validacao.router, prefix="/validacao", tags=["validação"])

# Rota de Chat
api_router.include_router(chat.router, prefix="/chat", tags=["chat"])

# Rota de Admin (Painel do Maestro)
api_router.include_router(admin.router, prefix="/admin", tags=["admin"])

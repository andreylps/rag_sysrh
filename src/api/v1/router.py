# src/api/v1/router.py

from fastapi import APIRouter

# Importa todos os endpoints, INCLUINDO O DASHBOARD
from src.api.v1.endpoints import (
    admin,
    analytics,
    audit,  # Novo import
    bi,
    chat,
    commercial,  # Novo import
    dashboard,
    debug,
    document_management,
    documentation,  # Novo import
    documents,
    knowledge,
    poc,
    quality,
    rcm,
    review,
    solicitacoes,
    system,
    validacao,
    webhook,
    workflow,
)

api_router = APIRouter()

# Rotas existentes
api_router.include_router(chat.router, prefix="/chat", tags=["chat"])

api_router.include_router(
    solicitacoes.router, prefix="/solicitacoes", tags=["solicitacoes"]
)
api_router.include_router(webhook.router, prefix="/webhook", tags=["webhook"])
api_router.include_router(dashboard.router, prefix="/dashboard", tags=["dashboard"])
api_router.include_router(documents.router, prefix="/documents", tags=["documents"])
api_router.include_router(bi.router, prefix="/bi", tags=["bi"])
api_router.include_router(review.router, prefix="/review", tags=["review"])
api_router.include_router(validacao.router, prefix="/validacao", tags=["validacao"])
api_router.include_router(rcm.router, prefix="/rcm", tags=["rcm"])
api_router.include_router(
    document_management.router, prefix="/doc-mgmt", tags=["document_management"]
)
api_router.include_router(knowledge.router, prefix="/knowledge", tags=["knowledge"])
api_router.include_router(admin.router, prefix="/admin", tags=["admin"])
api_router.include_router(analytics.router, prefix="/analytics", tags=["analytics"])
api_router.include_router(debug.router, prefix="/debug", tags=["debug"])
api_router.include_router(quality.router, prefix="/quality", tags=["quality"])
api_router.include_router(
    workflow.router, prefix="/workflow", tags=["workflow actions"]
)
api_router.include_router(
    documentation.router, prefix="/documentation", tags=["documentation"]
)
api_router.include_router(audit.router, prefix="/audit", tags=["audit"])
api_router.include_router(
    system.router, prefix="/system", tags=["system"]
)  # Infra Health Check

from src.api.v1.endpoints import scrum

api_router.include_router(scrum.router, prefix="/scrum", tags=["scrum"])

# Rota de RCM (Fluxo Evolutivo)
api_router.include_router(rcm.router, prefix="/rcm", tags=["rcm (fluxo evolutivo)"])

# Rota de Review Técnico (Fase 4.5)
api_router.include_router(review.router, prefix="/review", tags=["review técnico"])

# Rota de Qualidade (QCC)
# Rota de Qualidade (QCC)
api_router.include_router(quality.router, prefix="/quality", tags=["quality"])

# Rota de POC Generator
print("DEBUG: Including POC Router")
api_router.include_router(poc.router, prefix="/poc", tags=["poc generator"])
api_router.include_router(commercial.router, prefix="/commercial", tags=["commercial"])

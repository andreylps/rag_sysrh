import os

# Ensure project root is in sys.path
from dotenv import load_dotenv

load_dotenv()

# Ensure project root is in sys.path
import sys

# Tenta importar o router
import traceback  # Importante para debug

import uvicorn
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# Get the directory containing this file (src/api)
current_dir = os.path.dirname(os.path.abspath(__file__))
# Get the project root (parent of src)
project_root = os.path.dirname(os.path.dirname(os.path.dirname(current_dir)))

if project_root not in sys.path:
    sys.path.insert(0, project_root)

# Now we can import from src
# Strict absolute import
from contextlib import asynccontextmanager

from apscheduler.schedulers.asyncio import AsyncIOScheduler  # Adicionado

from src.api.v1.router import api_router
from src.services.file_watcher import FileWatcherService
from src.services.quality_service import check_for_stale_issues  # Adicionado

# ... imports ...


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Inicia o File Watcher
    data_dir = os.path.join(os.path.dirname(__file__), "..", "..", "data")
    # Garante que o diretório existe
    if not os.path.exists(data_dir):
        os.makedirs(data_dir, exist_ok=True)

    watcher = FileWatcherService(data_dir)
    watcher.start()
    print(f"🚀 File Watcher iniciado em: {data_dir}")

    # Inicializa e inicia o Scheduler de Qualidade
    scheduler = AsyncIOScheduler()
    # Roda a cada 1 hora (pode ajustar para minutes=1 para testes rápidos)
    scheduler.add_job(check_for_stale_issues, "interval", hours=1)

    # Inicializa o Scrum Master Agent (Fase SM.1)
    from src.services.scrum_master_service import scrum_master_service

    # Roda a cada 2 semanas (simulação de ciclo de Sprint)
    scheduler.add_job(scrum_master_service.plan_next_sprint, "interval", weeks=2)

    # Monitoramento Diário de Risco (Geral) - 09:00
    scheduler.add_job(
        scrum_master_service.monitor_active_sprint_issues,
        "cron",
        hour=9,
        minute=0,
        args=[False],
    )

    # Monitoramento Horário de Críticos (SLA Imediato)
    scheduler.add_job(
        scrum_master_service.monitor_active_sprint_issues,
        "interval",
        hours=1,
        args=[True],
    )

    # Snapshot Diário do Burndown - 20:00 (Fase SM.5)
    scheduler.add_job(
        scrum_master_service.take_daily_snapshot,
        "cron",
        hour=20,
        minute=0,
    )

    scheduler.start()
    print("🛡️ Quality Monitor & Scrum Master Scheduler iniciado.")

    # Inicializa o Scheduler do Auditor Autônomo (Fase 6.9)
    from src.services.qa_scheduler_service import qa_scheduler

    qa_scheduler.start()
    print("🤖 Autonomous QA Auditor Scheduler iniciado.")

    # Inicializa o Banco de Dados (SQLite)
    from src.core.database import Base, engine

    Base.metadata.create_all(bind=engine)
    print("💾 Database tables created/verified.")

    yield

    # Shutdown: Para o File Watcher e Scheduler
    scheduler.shutdown()
    print("🛑 Quality Monitor Scheduler parado.")
    watcher.stop()
    print("🛑 File Watcher parado.")


# Inicializa a aplicação FastAPI
app = FastAPI(
    title="noesys.ai API",
    description="API de orquestração para a Plataforma de Governança e Engenharia de Software Assistida por IA.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    debug=True,
    lifespan=lifespan,
)


# --- NOVO: Manipulador de Erros para Forçar Traceback no Terminal ---
@app.exception_handler(Exception)
async def debug_exception_handler(request: Request, exc: Exception):
    """
    Captura qualquer erro não tratado e imprime o traceback completo no terminal.
    Essencial para debugar erros 500 que não aparecem no log padrão.
    """
    print("\n" + "=" * 50)
    print(f"❌ ERRO CRÍTICO NA REQUISIÇÃO: {request.method} {request.url}")
    print("=" * 50)
    traceback.print_exc()  # <--- ISSO FORÇA A IMPRESSÃO DO ERRO
    print("=" * 50 + "\n")

    return JSONResponse(
        status_code=500,
        content={
            "detail": f"Erro interno no servidor: {exc!s}. Verifique os logs do terminal."
        },
    )


# -------------------------------------------------------------------

# Configuração de CORS
origins = [
    "*",  # LIBERADO GERAL PARA TESTE
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Inclui rotas
app.include_router(api_router, prefix="/api/v1")


# Health Check
@app.get("/", tags=["Health Check"])
async def root():
    return {
        "message": "Bem-vindo à API noesys.ai",
        "status": "operational",
        "version": "1.0.0",
        "docs": "/docs",
    }


if __name__ == "__main__":
    # Se rodar este arquivo diretamente, usa a porta 8080
    uvicorn.run("main:app", host="127.0.0.1", port=8080, reload=True)

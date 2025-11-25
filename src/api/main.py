import traceback  # Importante para debug

import uvicorn
from dotenv import load_dotenv
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

# Tenta importar o router
try:
    from src.api.v1.router import api_router
except ImportError:
    from api.v1.router import api_router

load_dotenv()

import os
from contextlib import asynccontextmanager

from src.services.file_watcher import FileWatcherService

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

    yield

    # Shutdown: Para o File Watcher
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
            "detail": f"Erro interno no servidor: {str(exc)}. Verifique os logs do terminal."
        },
    )


# -------------------------------------------------------------------

# Configuração de CORS
origins = [
    "http://localhost:5173",
    "http://127.0.0.1:5173",
    "http://localhost:3000",
    "http://localhost:5174",  # Adicionando a porta alternativa do Vite
    "http://127.0.0.1:5174",
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

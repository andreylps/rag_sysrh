import os

from fastapi import APIRouter

from src.rag_sysrh.neo4j_connection import get_graph

router = APIRouter()


@router.get("/health")
async def health_check():
    """
    Endpoint de Health Check para o Painel do Maestro.
    Verifica a conectividade com Neo4j, OpenAI e GitHub.
    """
    # 1. Check Neo4j
    neo4j_status = "down"
    neo4j_details = "Connection failed"
    try:
        graph = get_graph()
        if graph:
            # Executa uma query simples para validar a conexão
            graph.query("RETURN 1")
            neo4j_status = "up"
            neo4j_details = "Connected and responding"
        else:
            neo4j_details = "Client initialization failed"
    except Exception as e:
        neo4j_details = str(e)

    # 2. Check OpenAI (Verificação básica de chave)
    openai_status = "unknown"
    openai_details = "Key not found"
    if os.getenv("OPENAI_API_KEY"):
        openai_status = "up"
        openai_details = "API Key configured"
    else:
        openai_status = "down"

    # 3. Check GitHub (Verificação básica de token)
    github_status = "unknown"
    github_details = "Token not found"
    if os.getenv("GITHUB_TOKEN"):
        github_status = "up"
        github_details = "Token configured"
    else:
        github_status = "down"

    # Status Global
    global_status = "healthy"
    if neo4j_status == "down":
        global_status = "degraded"

    return {
        "status": global_status,
        "components": {
            "neo4j": {"status": neo4j_status, "details": neo4j_details},
            "openai": {"status": openai_status, "details": openai_details},
            "github": {"status": github_status, "details": github_details},
            "backend": {"status": "up", "details": "FastAPI running"},
        },
    }

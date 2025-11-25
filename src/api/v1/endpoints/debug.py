from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from rag_sysrh.analista_workflow import AnalistaWorkflow
from rag_sysrh.main import get_tools

router = APIRouter()


class AnaliseRequest(BaseModel):
    descricao: str


@router.post("/analisar")
async def debug_analisar(request: AnaliseRequest):
    """
    Endpoint de debug para testar o AnalistaWorkflow via API.
    """
    try:
        # Instancia o agente (idealmente, isso seria injetado como dependência)
        tools = get_tools()
        agente = AnalistaWorkflow(tools=tools)

        # Executa a análise de forma assíncrona
        resultado = await agente.arun(request.descricao)

        if not resultado:
            raise HTTPException(status_code=500, detail="Falha ao gerar análise.")

        return resultado.model_dump()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

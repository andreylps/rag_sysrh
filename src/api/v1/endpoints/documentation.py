import os
from typing import List

from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import FileResponse

from src.agents.librarian_agent import librarian

router = APIRouter()


@router.get("/list", response_model=List[dict])
async def list_documents(path: str = Query("", description="Subdiretório para listar")):
    """
    Lista todos os documentos disponíveis na base de conhecimento.
    """
    try:
        return librarian.list_documents(path)
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Erro ao listar documentos: {str(e)}"
        )


@router.get("/summarize")
async def summarize_document(
    file_path: str = Query(..., description="Caminho absoluto ou relativo do arquivo"),
):
    """
    Gera um resumo do documento especificado usando IA.
    """
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Arquivo não encontrado.")

    try:
        summary = await librarian.summarize_document(file_path)
        return {"summary": summary}
    except Exception as e:
        raise HTTPException(
            status_code=500, detail=f"Erro ao resumir documento: {str(e)}"
        )


@router.get("/search", response_model=List[dict])
async def search_documents(query: str = Query(..., description="Termo de busca")):
    """
    Busca documentos por nome ou conteúdo (busca híbrida).
    """
    try:
        return await librarian.search_documents(query)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Erro na busca: {str(e)}")


@router.get("/download")
async def download_document(
    file_path: str = Query(..., description="Caminho absoluto do arquivo"),
):
    """
    Faz o download do arquivo especificado.
    """
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Arquivo não encontrado.")

    # Segurança básica: garantir que o arquivo está dentro do projeto
    # (Em produção, isso deveria ser mais rigoroso)
    base_path = os.getcwd()
    if not os.path.abspath(file_path).startswith(base_path):
        raise HTTPException(
            status_code=403,
            detail="Acesso negado a arquivos fora do diretório do projeto.",
        )

    filename = os.path.basename(file_path)
    return FileResponse(
        path=file_path, filename=filename, media_type="application/octet-stream"
    )

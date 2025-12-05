import os

print("DEBUG: Loading src.api.v1.endpoints.poc")

from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse

from src.agents.poc_agent import POCAgent
from src.schemas.poc import POCRequestDTO
from src.services.poc_document_service import POCDocumentService

router = APIRouter()
poc_agent = POCAgent()
document_service = POCDocumentService()


@router.post("/generate")
async def generate_poc(request: POCRequestDTO):
    try:
        # 1. Gerar conteúdo com IA
        content = poc_agent.generate_poc_proposal_content(request)

        # 2. Criar documento DOCX
        filepath = document_service.create_poc_document(content)

        # Retornar caminho relativo ou nome do arquivo para download
        filename = os.path.basename(filepath)
        return {
            "message": "Proposta de POC gerada com sucesso!",
            "filename": filename,
            "content_preview": content,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/download/{filename}")
async def download_poc(filename: str):
    file_path = os.path.join("data/generated_proposals", filename)
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="Arquivo não encontrado")

    return FileResponse(
        path=file_path,
        filename=filename,
        media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    )


@router.post("/update-document")
async def update_poc_document(content: dict):
    try:
        # Regenera o documento com o conteúdo editado
        filepath = document_service.create_poc_document(content)
        filename = os.path.basename(filepath)

        return {"message": "Documento atualizado com sucesso!", "filename": filename}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse

from src.rag_sysrh.services.document_service import (
    DocumentGenerationRequest,
    DocumentGenerationResponse,
    DocumentService,
)

router = APIRouter()
service = DocumentService()


@router.post("/generate", response_model=DocumentGenerationResponse)
async def generate_documents(request: DocumentGenerationRequest):
    """
    Gera documentos (RCM e Memória de Cálculo) com base nos dados fornecidos.
    """
    response = service.generate_documents(request)
    if not response.rcm_filename and not response.memoria_filename:
        raise HTTPException(status_code=500, detail=response.message)
    return response


@router.get("/download")
async def download_file(path: str):
    """
    Faz o download de um arquivo gerado.
    O parâmetro 'path' deve ser o caminho retornado pelo endpoint de geração.
    """
    try:
        file_path = service.get_file_path(path)
        filename = file_path.name

        # Determina media_type
        media_type = "application/octet-stream"
        if filename.endswith(".docx"):
            media_type = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        elif filename.endswith(".xlsx"):
            media_type = (
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            )

        return FileResponse(path=file_path, filename=filename, media_type=media_type)
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="Arquivo não encontrado")
    except ValueError as e:
        raise HTTPException(status_code=403, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

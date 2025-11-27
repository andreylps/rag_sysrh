from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse

from src.rag_sysrh.services.document_service import DocumentService

router = APIRouter()
service = DocumentService()


@router.get("/rcm/{issue_number}/download", response_class=FileResponse)
async def download_rcm(issue_number: int):
    """
    Faz o download do arquivo RCM físico (DOCX) associado a uma issue.
    """
    try:
        file_path = service.get_rcm_file(issue_number)

        return FileResponse(
            path=file_path,
            filename=f"RCM_{issue_number}.docx",
            media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        )
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="RCM not found for this issue.")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/memcalc/{issue_number}/download", response_class=FileResponse)
async def download_memcalc(issue_number: int):
    """
    Faz o download do arquivo Memória de Cálculo físico (XLSX) associado a uma issue.
    """
    try:
        file_path = service.get_memcalc_file(issue_number)

        return FileResponse(
            path=file_path,
            filename=f"Memoria_Calculo_{issue_number}.xlsx",
            media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        )
    except FileNotFoundError:
        raise HTTPException(
            status_code=404, detail="Memória de Cálculo not found for this issue."
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

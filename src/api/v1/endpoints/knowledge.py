import os
import shutil
import traceback
from typing import List

from fastapi import APIRouter, File, HTTPException, UploadFile, status
from pydantic import BaseModel

from src.rag_sysrh.data_ingestion import DOCS_DIR
from src.rag_sysrh.ingestion_service import ingest_uploaded_file

router = APIRouter()


@router.post("/upload", status_code=status.HTTP_200_OK)
async def upload_knowledge(file: UploadFile = File(...)):
    """
    Recebe um arquivo (PDF ou DOCX), salva no disco e inicia o processo de ingestão
    para o banco de dados vetorial (Neo4j).
    """
    file_ext = os.path.splitext(file.filename)[1].lower()
    if file_ext not in [".pdf", ".docx"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Apenas arquivos .pdf e .docx são permitidos.",
        )

    os.makedirs(DOCS_DIR, exist_ok=True)
    file_path = os.path.join(DOCS_DIR, file.filename)

    try:
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        chunks_processed = ingest_uploaded_file(file_path)

    except Exception as e:
        print(f"Erro no upload/processamento: {e}")
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao processar o arquivo: {str(e)}",
        )

    return {
        "filename": file.filename,
        "status": "success",
        "chunks_processed": chunks_processed,
        "message": f"Arquivo '{file.filename}' processado e indexado com sucesso.",
    }


@router.get("/documents", response_model=List[dict])
async def list_knowledge():
    """
    Lista os arquivos que já foram indexados no banco de dados vetorial.
    Agrupa por nome do arquivo e conta os chunks.
    """
    try:
        # Obtém a conexão com o banco de dados
        from src.rag_sysrh.neo4j_connection import get_graph

        graph = get_graph()

        # Query Cypher melhorada
        # 1. Agrupa pelos metadados de origem (source)
        # 2. Extrai apenas o nome do arquivo do caminho completo usando split() e last()
        query = """
        MATCH (c:Chunk)
        // Supõe que a propriedade 'source' contém o caminho do arquivo.
        // Se no seu banco o nome for diferente (ex: 'filename'), mude 'c.source' aqui.
        RETURN
            last(split(c.source, '\\\\')) AS nome,
            count(c) AS chunks
        ORDER BY nome ASC
        """

        # ATENÇÃO: Se você estiver no Windows e os caminhos no banco usarem '\',
        # você precisará usar: last(split(c.source, '\\'))

        result = graph.query(query)

        # Mapeamos o resultado 'nome' do Cypher para a chave 'filename' no JSON
        files = [
            {
                "filename": record["nome"],  # <--- MUDOU DE "nome" PARA "filename"
                "chunks": record["chunks"],
            }
            for record in result
        ]

        return files

    except Exception as e:
        print(f"Erro ao listar arquivos: {e}")
        traceback.print_exc()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Erro ao conectar com o banco de dados: {str(e)}",
        )


@router.get("/manuals")
async def get_available_manuals():
    """
    Lista os manuais disponíveis para ingestão.
    """
    from src.rag_sysrh.ingestion_service import list_available_manuals

    return list_available_manuals()


class IngestionRequest(BaseModel):
    manuals: List[str]
    system_data: bool = True


@router.post("/ingest")
async def ingest_subset(request: IngestionRequest):
    """
    Executa a ingestão seletiva.
    """
    from src.rag_sysrh.ingestion_service import run_selective_ingestion

    try:
        return run_selective_ingestion(request.manuals, request.system_data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

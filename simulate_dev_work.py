import os
import sys

from dotenv import load_dotenv

load_dotenv()

# Add src to sys.path
sys.path.insert(0, os.getcwd())

from src.services.file_system_service import write_file_content


def simulate_work():
    print("🤖 Simulando trabalho do Agente Dev...")

    # 1. Model
    model_code = """from sqlmodel import SQLModel, Field
from typing import Optional

class Departamento(SQLModel, table=True):
    id: Optional[int] = Field(default=None, primary_key=True)
    nome: str
    sigla: str
"""
    write_file_content("app/models/departamento.py", model_code)
    print("✅ Criado app/models/departamento.py")

    # 2. Endpoint
    endpoint_code = """from fastapi import APIRouter
from app.models.departamento import Departamento

router = APIRouter()

@router.get("/departamentos")
def list_departamentos():
    return []
"""
    write_file_content("app/api/v1/endpoints/departamentos.py", endpoint_code)
    print("✅ Criado app/api/v1/endpoints/departamentos.py")


if __name__ == "__main__":
    simulate_work()

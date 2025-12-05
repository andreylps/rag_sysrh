from pydantic import BaseModel


class POCRequestDTO(BaseModel):
    problema_contexto: str
    objetivo_principal: str
    funcionalidades_desejadas: str
    kpis_sucesso: str
    prazo_restricoes: str | None = None

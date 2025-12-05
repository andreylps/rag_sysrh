# src/schemas/validation.py

from typing import List, Optional

from pydantic import BaseModel, Field

# Reutilizamos os Enums definidos no endpoint de solicitações para manter a consistência
# Certifique-se de que o caminho do import está correto para o seu projeto
from src.api.v1.endpoints.solicitacoes import PrioridadeSugerida, TipoSolicitacao


class ValidatedDataDTO(BaseModel):
    """
    Data Transfer Object (DTO) contendo os dados finais validados pelo analista humano.
    Este é o corpo que o frontend enviará ao aprovar.
    """

    tipo_solicitacao: TipoSolicitacao = Field(
        ..., description="Classificação final da demanda."
    )
    prioridade: PrioridadeSugerida = Field(
        ..., description="Prioridade final definida."
    )
    esforco_estimado: Optional[float] = Field(
        None, description="Estimativa de esforço em horas ou pontos de função."
    )
    # No futuro, receberemos uma lista de IDs de RCMs reais aqui.
    # Por enquanto, pode ser uma lista de strings (nomes ou códigos).
    rcms_relacionadas: List[str] = Field(
        default=[], description="Lista de identificadores de RCMs vinculadas."
    )
    comentarios_validacao: Optional[str] = Field(
        None, description="Justificativa ou observações do analista sobre a validação."
    )

    class Config:
        # Permite que os Enums sejam lidos pelos seus valores string no JSON
        use_enum_values = True
        json_schema_extra = {
            "example": {
                "tipo_solicitacao": "Melhoria",
                "prioridade": "Alta",
                "esforco_estimado": 40.5,
                "rcms_relacionadas": ["RCM-1234", "RCM-5678"],
                "comentarios_validacao": "Ajustado o tipo para Melhoria pois envolve alteração de regra de negócio, não bug.",
            }
        }

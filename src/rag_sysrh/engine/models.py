from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, Field


class TipoFuncao(str, Enum):
    ALI = "ALI"  # Arquivo Lógico Interno
    AIE = "AIE"  # Arquivo de Interface Externa
    EE = "EE"  # Entrada Externa
    SE = "SE"  # Saída Externa
    CE = "CE"  # Consulta Externa
    NAO_MENSURAVEL = "NAO_MENSURAVEL"  # Item não mensurável (PF=0)


class Complexidade(str, Enum):
    BAIXA = "Baixa"
    MEDIA = "Media"
    ALTA = "Alta"


class AvaliacaoRisco(BaseModel):
    """
    Rubrica de avaliação de risco e complexidade técnica (1-5).
    """

    impacto_backend: int = Field(
        ...,
        ge=1,
        le=5,
        description="Complexidade das alterações no Backend (1=Trivial, 5=Crítico)",
    )
    impacto_frontend: int = Field(
        ..., ge=1, le=5, description="Complexidade das alterações no Frontend"
    )
    risco_migracao: int = Field(
        ..., ge=1, le=5, description="Risco de perda de dados ou quebra de integridade"
    )
    esforco_testes: int = Field(
        ..., ge=1, le=5, description="Esforço necessário para validação e testes"
    )
    incerteza_requisitos: int = Field(
        ..., ge=1, le=5, description="Nível de ambiguidade ou falta de definição"
    )
    justificativa_geral: str = Field(
        ..., description="Explicação técnica para as notas atribuídas"
    )


class ItemFuncional(BaseModel):
    """
    Representa uma função de dados ou transação identificada pelo LLM.
    """

    nome: str = Field(..., description="Nome da função (ex: Manter Usuário)")
    tipo: TipoFuncao = Field(..., description="Tipo da função (ALI, AIE, EE, SE, CE)")
    descricao: str = Field(..., description="Descrição do que a função faz")
    der_estimado: int = Field(
        ..., description="Quantidade estimada de Dados Elementares Referenciados"
    )
    rlr_estimado: int = Field(
        ...,
        description="Quantidade estimada de Registros Lógicos Referenciados (ou ALIs referenciados)",
    )
    justificativa_contagem: str = Field(
        ..., description="Por que este item foi classificado assim?"
    )

    # Campos calculados (Determinísticos) - O LLM NÃO preenche isso
    complexidade: Optional[Complexidade] = None
    pf_bruto: int = 0


class ResultadoSISP(BaseModel):
    """
    Resultado final do cálculo SISP.
    """

    itens_calculados: List[ItemFuncional] = []
    pf_bruto_total: int = 0
    pf_liquido_total: float = 0.0
    prazo_estimado_dias: int = 0
    memoria_calculo_path: str = ""
    rcm_path: str = ""


class NonConformity(BaseModel):
    """Representa uma não-conformidade identificada pelo auditor."""

    type: str = Field(..., description="Tipo de erro (ex: SECURITY_RISK, PROCESS_SISP)")
    severity: str = Field(..., description="Severidade (CRITICAL, HIGH, MEDIUM, LOW)")
    description: str = Field(..., description="Descrição detalhada do problema")


class AuditVerdict(BaseModel):
    """Veredito final da auditoria de qualidade."""

    audit_status: str = Field(..., description="'APROVADO' ou 'REPROVADO'")
    audit_timestamp: str = Field(..., description="Data/Hora da auditoria")
    auditor_id: str = "AuditorAI_v1"
    quality_score: float = Field(..., description="Nota de qualidade técnica (0-5)")
    non_conformities: List[NonConformity] = []
    final_comments: str = Field(..., description="Comentários finais do auditor")


class EstadoEngenharia(BaseModel):
    """
    Estado global do fluxo de engenharia no LangGraph.
    """

    # Inputs Iniciais
    solicitacao_original: str

    # Camada 1: Inteligência (LLM)
    diagnostico_tecnico: str = ""
    avaliacao_risco: Optional[AvaliacaoRisco] = None
    itens_identificados: List[ItemFuncional] = []

    # Camada 2: Input Humano (HIL)
    deflator_tabela0: Optional[float] = None  # O fluxo PAUSA até isso ser preenchido

    # Camada 3: Motor Determinístico (Python)
    resultado_sisp: Optional[ResultadoSISP] = None

    # Camada 4: Auditoria (Quality Gate)
    audit_verdict: Optional[AuditVerdict] = None

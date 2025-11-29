import logging
import os
from datetime import UTC, datetime, timedelta
from enum import Enum
from pathlib import Path
from typing import Any

from docx import Document
from langchain_core.exceptions import OutputParserException
from langchain_core.messages import HumanMessage, SystemMessage
from langchain_core.output_parsers import PydanticOutputParser
from langchain_openai import ChatOpenAI
from pydantic import BaseModel, Field, validator
from pypdf import PdfReader

from src.core.quality_alerts import add_alert, get_all_alerts
from src.services.code_analysis_service import code_analysis_service
from src.services.github_service import search_issues_generic
from src.services.qa_scheduler_service import qa_scheduler

# Tenta importar get_all_reports se não houver ciclo
try:
    from src.services.audit_service import get_all_reports
except ImportError:

    def get_all_reports() -> list[Any]:
        return []


# Configuração de Logging
logger = logging.getLogger(__name__)

STALE_HOURS = 24  # Limite de horas para considerar uma issue estagnada
SUMMARY_TRUNCATE_LEN = 150  # Tamanho máximo do resumo no dashboard

# --- Configuração do Modelo LLM ---
llm = ChatOpenAI(model=os.getenv("OPENAI_MODEL_NAME", "gpt-4o"), temperature=0)

# --- Caminho para os Guias SISP de Ponto de Função ---
SISP_GUIDES_DIR = Path("data/guia_metricas")
SISP_PF_GUIDELINES_FILE = SISP_GUIDES_DIR / "Guia-Contagem-Pontos-de-Funcao.pdf"

# Variável global para armazenar o conteúdo do guia SISP
SISP_PF_GUIDELINES_CONTENT: str = ""


# --- Funções Auxiliares ---


def extract_text_from_docx(file_path: Path | str) -> str:
    """
    Extrai todo o texto de um arquivo DOCX.
    """
    path = Path(file_path)
    try:
        doc = Document(str(path))
    except Exception:
        msg = f"Erro ao extrair texto do DOCX em {path}"
        logger.exception(msg)
        err_msg = f"Não foi possível ler o arquivo DOCX em {path}"
        raise ValueError(err_msg) from None
    else:
        return "\n".join([para.text for para in doc.paragraphs])


def extract_text_from_pdf(file_path: Path | str) -> str:
    """
    Extrai todo o texto de um arquivo PDF.
    """
    path = Path(file_path)
    try:
        reader = PdfReader(str(path))
        text = ""
        for page in reader.pages:
            text += page.extract_text() + "\n"
    except Exception:
        msg = f"Erro ao extrair texto do PDF em {path}"
        logger.exception(msg)
        err_msg = f"Não foi possível ler o arquivo PDF em {path}"
        raise ValueError(err_msg) from None
    else:
        return text


def load_sisp_pf_guidelines() -> str:
    """
    Carrega o conteúdo do guia SISP de Ponto de Função da pasta `data/guia_metricas`.
    """
    global SISP_PF_GUIDELINES_CONTENT  # noqa: PLW0603

    if SISP_PF_GUIDELINES_CONTENT:
        return SISP_PF_GUIDELINES_CONTENT

    if not SISP_PF_GUIDELINES_FILE.exists():
        logger.warning(
            "Arquivo do guia SISP de PF não encontrado em: %s. "
            "O Agente de Qualidade não terá este contexto.",
            SISP_PF_GUIDELINES_FILE,
        )
        return ""

    try:
        if SISP_PF_GUIDELINES_FILE.suffix.lower() == ".pdf":
            SISP_PF_GUIDELINES_CONTENT = extract_text_from_pdf(SISP_PF_GUIDELINES_FILE)
        elif SISP_PF_GUIDELINES_FILE.suffix.lower() == ".docx":
            SISP_PF_GUIDELINES_CONTENT = extract_text_from_docx(SISP_PF_GUIDELINES_FILE)
        else:
            with SISP_PF_GUIDELINES_FILE.open(encoding="utf-8") as f:
                SISP_PF_GUIDELINES_CONTENT = f.read()

        logger.info(
            "Guia SISP carregado com sucesso (%d caracteres).",
            len(SISP_PF_GUIDELINES_CONTENT),
        )
    except Exception:
        logger.exception("Erro ao carregar o guia SISP")
        return ""
    else:
        return SISP_PF_GUIDELINES_CONTENT


# Carregar o guia SISP na inicialização do módulo
load_sisp_pf_guidelines()


# --- Definição dos Critérios de Qualidade (Base de Conhecimento) ---


class QACriterionCategory(str, Enum):
    """Categorias para os critérios de qualidade."""

    ISO_12207 = "ISO/IEC 12207 (Processos de Ciclo de Vida)"
    ISO_25000 = "ISO/IEC 25000 (Qualidade de Produto de Software)"
    ISO_27000 = "ISO/IEC 27000 (Segurança da Informação)"
    ISO_9001 = "ISO 9001 (Gestão da Qualidade)"


class QACriterion(BaseModel):
    """Representa um critério de qualidade individual."""

    id: str
    category: QACriterionCategory
    description: str
    severity: str = "High"  # Pode ser "High", "Medium", "Low"


# Lista de critérios baseados nas normas ISO relevantes.
QA_DOCUMENT_CRITERIA: list[QACriterion] = [
    # ISO/IEC 12207 - Foco na precisão funcional e utilidade
    QACriterion(
        id="FUNC_ACCURACY",
        category=QACriterionCategory.ISO_12207,
        description=(
            "O manual reflete com precisão a funcionalidade implementada ou alterada, "
            "sem informações obsoletas ou incorretas."
        ),
    ),
    QACriterion(
        id="TARGET_AUDIENCE",
        category=QACriterionCategory.ISO_12207,
        description=(
            "O conteúdo é adequado para o público-alvo pretendido (operadores, "
            "usuários finais), usando terminologia apropriada e nível de detalhe "
            "adequado."
        ),
    ),
    # ISO/IEC 25000 - Foco na qualidade do documento em si
    QACriterion(
        id="USABILITY_CLARITY",
        category=QACriterionCategory.ISO_25000,
        description=(
            "A linguagem é clara, concisa, direta e livre de jargões técnicos "
            "desnecessários ou ambiguidades. Frases curtas e objetivas são preferíveis."
        ),
    ),
    QACriterion(
        id="USABILITY_STRUCTURE",
        category=QACriterionCategory.ISO_25000,
        description=(
            "O documento possui uma estrutura lógica e bem definida (ex: Introdução, "
            "Pré-requisitos, Passo a Passo, Solução de Problemas, Glossário), "
            "facilitando a navegação e a localização de informações. "
            "Inclui um índice ou sumário, se o tamanho justificar."
        ),
    ),
    QACriterion(
        id="MAINTAINABILITY",
        category=QACriterionCategory.ISO_25000,
        description=(
            "O documento é modular e organizado de forma que futuras atualizações "
            "sejam fáceis de realizar, sem afetar outras seções desnecessariamente."
        ),
    ),
    QACriterion(
        id="COMPLETENESS",
        category=QACriterionCategory.ISO_25000,
        description=(
            "O manual fornece todas as informações essenciais para a operação e "
            "compreensão da funcionalidade que se propõe a cobrir, sem lacunas "
            "críticas."
        ),
    ),
    # ISO/IEC 27000 - Foco na segurança da informação
    QACriterion(
        id="SEC_NO_SECRETS",
        category=QACriterionCategory.ISO_27000,
        description=(
            "O manual NÃO contém informações sensíveis, como credenciais hardcoded, "
            "chaves de API, endereços IP internos críticos, dados pessoais (PII) "
            "não mascarados, ou detalhes de infraestrutura confidencial."
        ),
        severity="Critical",
    ),
    QACriterion(
        id="SEC_BEST_PRACTICES",
        category=QACriterionCategory.ISO_27000,
        description=(
            "O manual, quando relevante, orienta sobre práticas seguras de uso do "
            "sistema (ex: importância de senhas fortes, logoff, não compartilhamento "
            "de credenciais, reconhecimento de ameaças)."
        ),
    ),
    # ISO 9001 - Foco na consistência, rastreabilidade e controle
    QACriterion(
        id="QMS_CONSISTENCY",
        category=QACriterionCategory.ISO_9001,
        description=(
            "O layout, formatação (fontes, cabeçalhos, espaçamento, uso de cores) "
            "e estilo de escrita são consistentes em todo o documento e seguem os "
            "padrões de identidade visual e documental da organização."
        ),
    ),
    QACriterion(
        id="QMS_IDENTIFICATION",
        category=QACriterionCategory.ISO_9001,
        description=(
            "O documento possui um título claro, identificação de versão, data de "
            "criação/última atualização, e autor/responsável pela revisão."
        ),
    ),
    QACriterion(
        id="QMS_TRACEABILITY",
        category=QACriterionCategory.ISO_9001,
        description=(
            "Há uma referência clara à solicitação de mudança (Issue ID, RCM, "
            "Memória de Cálculo) que originou o manual ou sua atualização, "
            "garantindo rastreabilidade do processo."
        ),
    ),
]


# --- Estruturas de Saída do Agente (Pydantic) ---


class QAIssue(BaseModel):
    """Representa um problema específico de qualidade encontrado no documento."""

    criterion_id: str = Field(
        ...,
        description=(
            "O ID do critério de qualidade que foi violado. "
            "Deve ser um dos IDs de QA_DOCUMENT_CRITERIA."
        ),
    )
    description: str = Field(
        ...,
        description=(
            "Uma descrição detalhada e específica do problema encontrado no texto "
            "do manual. Cite trechos se relevante."
        ),
    )
    location: str | None = Field(
        None,
        description=(
            "A localização aproximada do problema no documento "
            "(ex: 'Seção 2.1', 'Parágrafo 3', 'Página 5')."
        ),
    )
    recommendation: str = Field(
        ...,
        description=(
            "Uma recomendação clara e acionável sobre como corrigir ou melhorar "
            "o aspecto do documento."
        ),
    )


class DocumentValidationResult(BaseModel):
    """O resultado consolidado da validação do documento."""

    is_compliant: bool = Field(
        ...,
        description=(
            "Indica se o documento foi aprovado (True) ou reprovado (False) "
            "na validação de qualidade."
        ),
    )
    summary: str = Field(
        ...,
        description=(
            "Um resumo executivo da avaliação da qualidade do documento, "
            "destacando pontos fortes e fracos gerais."
        ),
    )
    issues: list[QAIssue] = Field(
        default_factory=list,
        description=(
            "Uma lista de problemas de qualidade encontrados. "
            "Vazia se o documento for compatível."
        ),
    )
    timestamp: datetime = Field(
        default_factory=datetime.utcnow,
        description="Data e hora da validação.",
    )

    @validator("is_compliant", always=True)
    def check_compliance_based_on_issues(
        cls,  # noqa: N805
        v: bool,  # noqa: FBT001
        values: dict[str, Any],
    ) -> bool:
        """Garante que is_compliant seja False se houver issues."""
        if values.get("issues") and v is True:
            logger.warning(
                "LLM retornou is_compliant=True mas com issues. "
                "Corrigindo para is_compliant=False."
            )
            return False
        return v


# --- Prompt do Sistema para o Agente de Qualidade ---

# Formata a lista de critérios para inclusão no prompt
criteria_text = "\n".join(
    [
        f"- [{c.id}] ({c.category.value}): {c.description} (Severidade: {c.severity})"
        for c in QA_DOCUMENT_CRITERIA
    ]
)

DOC_QA_SYSTEM_PROMPT = f"""
Você é o 'Agente de Qualidade de Documentação' do sistema RAG_SYSRH.
Sua função é atuar como um auditor rigoroso, garantindo que todos os manuais
operacionais gerados atendam aos mais altos padrões de qualidade, baseados em
normas ISO (12207, 25000, 27000, 9001) e nas diretrizes internas da organização.

Sua análise deve ser crítica, imparcial e construtiva. Seu objetivo é impedir que
documentação de baixa qualidade, imprecisa ou insegura chegue aos usuários finais.

### Seus Critérios de Avaliação (Knowledge Base):

Você deve avaliar o documento fornecido ÚNICA E EXCLUSIVAMENTE em relação aos
seguintes critérios:

{criteria_text}

### Guias Adicionais para Auditoria (Contagem de Pontos de Função - SISP):
Você também possui acesso a um conjunto de guias da SISP para contagem de Pontos de
Função. Quando você precisar auditar estimativas ou contagens de PF presentes em
documentos (ex: Memória de Cálculo), você deve consultar este guia para validar a
aderência às normas SISP.

Conteúdo do Guia SISP de Pontos de Função (Referência):
---
{SISP_PF_GUIDELINES_CONTENT}
---

### Sua Tarefa:

1.  **Ler e Analisar:** Leia atentamente o conteúdo completo do manual operacional
    fornecido.
2.  **Avaliar Critério por Critério:** Verifique o conteúdo em relação a CADA UM dos
    critérios listados acima.
3.  **Identificar Problemas (Issues):** Se o documento falhar em atender a qualquer
    aspecto de um critério, você deve registrar isso como um 'Issue'.
    * Para cada problema, identifique o ID do critério violado.
    * Descreva o problema de forma clara e específica, citando exemplos do texto,
      se possível.
    * Forneça uma localização aproximada (ex: seção, parágrafo) para facilitar a
      correção.
    * Ofereça uma recomendação clara e acionável sobre como corrigir o problema.
4.  **Determinar a Conformidade Geral:**
    * Se **QUALQUER** problema (Issue) for encontrado, o documento deve ser considerado
      **NÃO CONFORME** (`is_compliant = False`).
    * Se **NENHUM** problema for encontrado e o documento atender satisfatoriamente a
      todos os critérios, ele deve ser considerado **CONFORME** (`is_compliant = True`).
    * **Atenção Especial à Segurança:** Qualquer violação do critério `SEC_NO_SECRETS`
      (exposição de segredos) é uma falha crítica e deve resultar em reprovação
      imediata, independentemente de outros critérios.
5.  **Gerar Relatório:** Produza um resumo executivo da sua avaliação e liste todos os
    problemas encontrados (se houver).

Seja minucioso. A qualidade da documentação é essencial para a operação segura e
eficiente do sistema.
"""

# --- Configuração do Parser e do Agente ---
output_parser = PydanticOutputParser(pydantic_object=DocumentValidationResult)
format_instructions = output_parser.get_format_instructions()


# --- Funções de Serviço ---


async def check_for_stale_issues() -> None:
    """
    Verifica se há issues estagnadas em etapas críticas do fluxo.
    Roda periodicamente via scheduler.
    """
    logger.info("🛡️ [Quality Monitor] Iniciando verificação de issues estagnadas...")

    try:
        cutoff_date = datetime.now(UTC) - timedelta(hours=STALE_HOURS)
        cutoff_date_formatted = cutoff_date.strftime("%Y-%m-%dT%H:%M:%SZ")

        query_analyst = (
            f"is:issue is:open "
            f"label:status:aguardando-validacao "
            f"updated:<{cutoff_date_formatted}"
        )

        query_tech = (
            f"is:issue is:open "
            f"label:status:aguardando-review-tecnico "
            f"updated:<{cutoff_date_formatted}"
        )

        stale_analyst = await search_issues_generic(query_analyst)
        stale_tech = await search_issues_generic(query_tech)

        if stale_analyst:
            logger.warning(
                "⚠️ [Quality Alert] %d issues estagnadas na Validação (> %dh): %s",
                len(stale_analyst),
                STALE_HOURS,
                [i["number"] for i in stale_analyst],
            )
            for issue_data in stale_analyst:
                await add_alert(
                    message=(
                        f"Issue #{issue_data['number']} ('{issue_data['title']}') "
                        f"está estagnada na validação há mais de {STALE_HOURS}h."
                    ),
                    category="stale_issue_validation",
                    issue_number=issue_data["number"],
                )

        if stale_tech:
            logger.warning(
                "⚠️ [Quality Alert] %d issues estagnadas no Review Técnico (> %dh): %s",
                len(stale_tech),
                STALE_HOURS,
                [i["number"] for i in stale_tech],
            )
            for issue_data in stale_tech:
                await add_alert(
                    message=(
                        f"Issue #{issue_data['number']} ('{issue_data['title']}') "
                        f"está estagnada no review técnico há mais de {STALE_HOURS}h."
                    ),
                    category="stale_issue_tech_review",
                    issue_number=issue_data["number"],
                )

        if not stale_analyst and not stale_tech:
            logger.info("✅ [Quality Monitor] Nenhuma issue estagnada encontrada.")

    except Exception:
        logger.exception("❌ [Quality Monitor] Erro ao verificar issues estagnadas")


async def validate_operational_manual(
    manual_file_path: str, issue: dict[str, Any]
) -> DocumentValidationResult:
    """
    Valida o manual operacional de um determinado caminho de arquivo utilizando o
    Agente de Qualidade (LLM).

    Esta função primeiro extrai o texto do arquivo DOCX, depois monta o prompt completo
    com as instruções do sistema, os critérios de qualidade, o conteúdo do documento
    a ser analisado e as instruções de formatação da saída. Em seguida, invoca a LLM
    e faz o parse da resposta para um objeto estruturado.

    Args:
        manual_file_path (str): O caminho completo para o arquivo DOCX do manual.
        issue (Dict[str, Any]): O dicionário da issue do GitHub relacionada.

    Returns:
        DocumentValidationResult: O resultado estruturado da validação.

    Raises:
        ValueError: Se o arquivo DOCX não puder ser lido.
        Exception: Se houver erro na comunicação com a LLM ou no parsing da resposta.
    """
    issue_num = issue.get("number")
    logger.info(
        "Iniciando validação do manual operacional para issue #%s em: %s",
        issue_num,
        manual_file_path,
    )

    try:
        # 1. Extrair o texto do DOCX
        document_content = extract_text_from_docx(manual_file_path)
        if not document_content.strip():
            logger.warning(
                "Manual em %s está vazio ou não pôde ser lido. Reprovando.",
                manual_file_path,
            )
            await add_alert(
                f"Falha na validação do manual (Issue #{issue_num}): "
                "O arquivo DOCX está vazio ou não contém texto.",
                category="document_qa_failure",
                issue_number=issue_num,
            )
            return DocumentValidationResult(
                is_compliant=False,
                summary="O manual está vazio ou não pôde ser lido para validação.",
                issues=[
                    QAIssue(
                        criterion_id="CONTENT_MISSING",
                        description="O arquivo DOCX está vazio ou não contém texto.",
                        recommendation=(
                            "Garantir que o Agente de Documentação gere conteúdo."
                        ),
                    )
                ],
            )

        # 2. Monta as mensagens para a LLM
        messages = [
            SystemMessage(content=DOC_QA_SYSTEM_PROMPT),
            HumanMessage(
                content=(
                    f"### Conteúdo do Manual Operacional para Validar "
                    f"(Issue #{issue_num} - '{issue.get('title')}'):\n\n"
                    f"{document_content}\n\n"
                    f"### Formato de Saída Esperado:\n\n{format_instructions}"
                )
            ),
        ]

        # 3. Invoca a LLM
        response = await llm.ainvoke(messages)

        # 4. Faz o parsing da resposta da LLM para o modelo Pydantic
        validation_result = output_parser.parse(response.content)

        logger.info(
            "Validação concluída para issue #%s. Status de conformidade: %s",
            issue_num,
            validation_result.is_compliant,
        )
        if not validation_result.is_compliant:
            logger.warning(
                "Manual da issue #%s reprovado. Encontrados %d problemas.",
                issue_num,
                len(validation_result.issues),
            )
            feedback_summary = "; ".join(
                [
                    f"[{iss.criterion_id}] {iss.description}"
                    for iss in validation_result.issues
                ]
            )
            await add_alert(
                f"Falha na validação do manual operacional para issue #{issue_num}. "
                f"Detalhes: {feedback_summary}",
                category="document_qa_failure",
                issue_number=issue_num,
            )

    except ValueError as e:  # Captura erros da extração do DOCX
        logger.exception(
            "Erro ao processar arquivo DOCX para validação da issue #%s", issue_num
        )
        await add_alert(
            f"Erro técnico ao validar manual da issue #{issue_num}: "
            f"Não foi possível ler o arquivo DOCX. Erro: {e!s}",
            category="system_error_qa",
            issue_number=issue_num,
        )
        return DocumentValidationResult(
            is_compliant=False,
            summary=f"Falha técnica: Não foi possível ler o arquivo DOCX. Erro: {e!s}",
            issues=[
                QAIssue(
                    criterion_id="SYSTEM_READ_ERROR",
                    description=(
                        f"O arquivo DOCX em '{manual_file_path}' não pôde ser lido."
                    ),
                    recommendation=(
                        "Verificar o caminho do arquivo e a integridade do DOCX."
                    ),
                )
            ],
        )
    except OutputParserException as e:
        logger.exception(
            "Erro ao fazer parse da resposta da LLM para validação de documento "
            "da issue #%s",
            issue_num,
        )
        await add_alert(
            f"Erro técnico ao validar manual da issue #{issue_num}: "
            f"Resposta da IA inconsistente. Erro: {e!s}",
            category="system_error_qa",
            issue_number=issue_num,
        )
        return DocumentValidationResult(
            is_compliant=False,
            summary=(
                f"Falha técnica na validação: Não foi possível interpretar a resposta "
                f"do agente de qualidade. Erro: {e!s}"
            ),
            issues=[
                QAIssue(
                    criterion_id="SYSTEM_LLM_PARSE_ERROR",
                    description=(
                        "A resposta da IA não pôde ser processada corretamente."
                    ),
                    recommendation="Verificar logs do sistema e tentar novamente.",
                )
            ],
        )
    except Exception as e:
        logger.exception(
            "Erro inesperado durante a validação do documento da issue #%s", issue_num
        )
        await add_alert(
            f"Erro inesperado ao validar manual da issue #{issue_num}. Erro: {e!s}",
            category="system_error_qa",
            issue_number=issue_num,
        )
        return DocumentValidationResult(
            is_compliant=False,
            summary=(
                f"Falha técnica na validação: Ocorreu um erro inesperado. Erro: {e!s}"
            ),
            issues=[
                QAIssue(
                    criterion_id="SYSTEM_UNEXPECTED_ERROR",
                    description=(
                        "Ocorreu um erro interno desconhecido durante a validação."
                    ),
                    recommendation=(
                        "Contatar o administrador do sistema e verificar os logs."
                    ),
                )
            ],
        )
    else:
        return validation_result


async def audit_function_points(
    _document_content: str, issue: dict[str, Any]
) -> dict[str, Any]:
    """
    Placeholder para uma futura função que irá auditar a contagem de Pontos de Função
    em um documento (ex: Memória de Cálculo), usando o guia SISP como referência.

    Args:
        _document_content (str): O conteúdo textual do documento a ser auditado.
                                 (Não utilizado no placeholder)
        issue (Dict[str, Any]): O dicionário da issue do GitHub relacionada.

    Returns:
        Dict[str, Any]: Um dicionário com o resultado da auditoria.
    """
    logger.info(
        "Iniciando auditoria de Pontos de Função para issue #%s "
        "(em desenvolvimento)...",
        issue.get("number"),
    )
    # A implementação real desta função envolveria um prompt específico para a LLM
    # para analisar a contagem de PF no document_content.

    return {
        "status": "pending_implementation",
        "feedback": (
            "A funcionalidade de auditoria de Pontos de Função está em "
            "desenvolvimento. O Agente de Qualidade já tem acesso ao guia SISP, "
            "mas a lógica de auditoria ainda não foi implementada."
        ),
    }


async def get_qa_dashboard_metrics() -> dict[str, Any]:
    """
    Calcula e retorna as métricas para o dashboard de qualidade (Quality Control Room).
    """
    alerts = get_all_alerts()

    # 1. Dados Reais do Scheduler e Relatórios
    schedule_stats = qa_scheduler.get_schedule_stats()
    reports = get_all_reports()
    upcoming_audits = qa_scheduler.get_upcoming_audits()

    # 2. Contagem de Gargalos Ativos
    active_bottlenecks = len(alerts)
    stale_issues_count = sum(
        1 for a in alerts if "stale_issue" in a.get("category", "")
    )
    doc_failures_count = sum(
        1 for a in alerts if "document_qa_failure" in a.get("category", "")
    )

    # 3. Taxa de Conformidade (Baseada em Relatórios e Alertas)
    base_compliance = 100
    penalty_per_alert = 2
    compliance_rate = max(0, base_compliance - (len(alerts) * penalty_per_alert))

    # 4. Distribuição de Falhas / Tipos de Auditoria
    if alerts:
        categories = {}
        for a in alerts:
            cat = a.get("category", "Outros")
            categories[cat] = categories.get(cat, 0) + 1

        failure_distribution = [
            {"name": k.replace("_", " ").title(), "value": v}
            for k, v in categories.items()
        ]
    else:
        # Mostrar distribuição de auditorias agendadas/realizadas
        # como "Foco da Qualidade"
        by_type = schedule_stats.get("by_type", {})
        if by_type:
            failure_distribution = [
                {
                    "name": k.replace("_AUDIT", "").replace("_CHECK", "").title(),
                    "value": v,
                }
                for k, v in by_type.items()
                if v > 0
            ]
        else:
            failure_distribution = [{"name": "Sem Dados", "value": 100}]

    # 5. Calendário de Auditorias (Próximos 5 eventos reais)
    audit_schedule_list = [
        {
            "date": audit.scheduled_date.strftime("%d/%m"),
            "event": audit.audit_type.replace("_AUDIT", "")
            .replace("_CHECK", "")
            .title(),
            "type": "auto",
        }
        for audit in upcoming_audits[:5]
    ]

    # 6. Relatórios PDCA Reais
    pdca_reports_list = []
    for r in reports[:5]:
        summary_text = r.summary
        if len(summary_text) > SUMMARY_TRUNCATE_LEN:
            summary_text = summary_text[:SUMMARY_TRUNCATE_LEN] + "..."

        pdca_reports_list.append(
            {
                "id": r.id,
                "title": f"Relatório {r.audit_type}",
                "status": "Concluído",
                "summary": summary_text,
                "generation_date": r.generation_date,
                "metrics_snapshot": r.metrics_snapshot,
            }
        )

    return {
        "compliance_rate": compliance_rate,
        "active_bottlenecks": active_bottlenecks,
        "stale_issues_count": stale_issues_count,
        "doc_failures_count": doc_failures_count,
        "failure_distribution": failure_distribution,
        "total_audits": schedule_stats.get("total", 0),
        "alerts": alerts,
        "audit_schedule": audit_schedule_list,
        "pdca_reports": pdca_reports_list,
    }


async def get_iso_indicators() -> dict[str, Any]:
    """
    Coleta e calcula indicadores de qualidade baseados nas normas ISO.
    Alguns dados são reais (do sistema), outros são simulados para este MVP.
    """
    # Dados reais do sistema
    alerts = get_all_alerts()
    schedule_stats = qa_scheduler.get_schedule_stats()

    # Calcular métricas reais baseadas em alertas
    doc_failures = sum(
        1 for a in alerts if "document_qa_failure" in a.get("category", "")
    )
    security_alerts = sum(1 for a in alerts if "security" in a.get("category", ""))
    process_alerts = sum(1 for a in alerts if "stale" in a.get("category", ""))

    total_audits = schedule_stats.get("total", 0)

    # --- 1. PROCESSOS (ISO 12207 / 15504 SPICE) ---
    # Simulação realista baseada em "desvios" (alerts)
    process_compliance = max(0, 100 - (process_alerts * 5))

    maturity_threshold = 80
    process_metrics = {
        "compliance_rate": process_compliance,
        "non_conformities": process_alerts,
        "avg_resolution_time_hours": 24.5,  # Mock
        "maturity_level": 2 if process_compliance < maturity_threshold else 3,
        "process_improvement_requests": 5,  # Mock
    }

    # --- 2. PRODUTO (ISO 25000) ---
    # Métricas reais de análise estática
    avg_cc = code_analysis_service.analyze_complexity()
    avg_mi = code_analysis_service.analyze_maintainability()
    tech_debt = code_analysis_service.estimate_technical_debt(avg_mi)

    product_metrics = {
        "functional_coverage": 85.0,  # Mock
        "production_bugs": 3,  # Mock (poderia vir do GitHub)
        "technical_debt_ratio": tech_debt,  # Real (Radon)
        "mtbf_hours": 720,  # Mock (30 dias)
        "cyclomatic_complexity_avg": avg_cc,  # Real (Radon)
        "maintainability_index": avg_mi,  # Real (Radon)
        "ux_requirements_met_percent": 92.0,  # Mock
    }

    # --- 3. SEGURANÇA (ISO 27001) ---
    security_metrics = {
        "critical_vulnerabilities": 0,  # Mock (idealmente 0)
        "high_vulnerabilities": security_alerts,  # Real
        "security_incidents": 1,  # Mock
        "risk_mitigation_rate": 95.0,  # Mock
        "lgpd_compliance_rate": 100.0,  # Mock
    }

    # --- 4. DOCUMENTAÇÃO (ISO 9001 / 29148) ---
    doc_compliance = max(0, 100 - (doc_failures * 10))
    doc_metrics = {
        "compliance_rate": doc_compliance,
        "completeness_index": 88.0,  # Mock
        "rework_rate": 15.0 if doc_failures > 0 else 5.0,  # Lógica simples
        "requirements_traced_percent": 90.0,  # Mock
    }

    # --- 5. AUDITORIA & GOVERNANÇA ---
    audit_metrics = {
        "total_audits": total_audits,
        "audits_on_time_percent": 100.0,  # Mock
        "gap_correction_rate": 80.0,  # Mock
        "quality_goals_met_percent": 85.0,  # Mock
    }

    # --- 6. TESTES (ISO 29119) ---
    test_metrics = {
        "test_coverage_percent": 78.5,  # Mock
        "defect_detection_rate": 92.0,  # Mock
        "cost_of_quality_ratio": 15.0,  # Mock
    }

    return {
        "process": process_metrics,
        "product": product_metrics,
        "security": security_metrics,
        "documentation": doc_metrics,
        "audit": audit_metrics,
        "tests": test_metrics,
        "generated_at": datetime.now(UTC).isoformat(),
    }

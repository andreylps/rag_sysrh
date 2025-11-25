# src/api/v1/endpoints/validacao.py

import logging
from typing import List

from fastapi import APIRouter, Body, HTTPException, Path, status

from src.schemas.validation import ValidatedDataDTO

# Imports dos serviços
from src.services.github_service import (
    get_issue_details,
    list_issues_by_label,
    post_comment,
    update_issue_labels,
)
from src.services.neo4j_service import (
    save_validated_demand_data,  # <--- ESTE IMPORT AGORA VAI FUNCIONAR
)

router = APIRouter()
logger = logging.getLogger(__name__)

# Labels de fluxo de trabalho
LABEL_AGUARDANDO_VALIDACAO = "status:aguardando-validacao"
LABEL_VALIDADO = "status:validado"  # Label a ser adicionada após aprovação


@router.get("/backlog", response_model=List[dict])
async def get_validation_backlog():
    """
    Retorna a lista de issues que estão aguardando validação humana.
    """
    try:
        issues = await list_issues_by_label(
            label=LABEL_AGUARDANDO_VALIDACAO, state="open"
        )
        return issues
    except Exception as e:
        logger.error(f"Erro ao buscar backlog de validação: {e}")
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Falha ao se comunicar com o GitHub para buscar o backlog: {str(e)}",
        )


@router.get("/issues/{issue_number}", response_model=dict)
async def get_issue(
    issue_number: int = Path(..., description="Número da issue no GitHub", ge=1),
):
    """
    Retorna os detalhes de uma issue específica do GitHub.
    """
    try:
        issue = await get_issue_details(issue_number)
        return issue
    except Exception as e:
        logger.error(f"Erro ao buscar detalhes da issue #{issue_number}: {e}")
        if "Not Found" in str(e):
            raise HTTPException(
                status_code=404, detail=f"Issue #{issue_number} não encontrada."
            )
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Erro ao buscar issue no GitHub: {str(e)}",
        )


@router.post("/{issue_number}/approve", status_code=status.HTTP_200_OK)
async def approve_validation(
    issue_number: int = Path(..., description="Número da issue no GitHub", ge=1),
    validated_data: ValidatedDataDTO = Body(
        ..., description="Dados validados pelo analista"
    ),
):
    """
    Aprova a validação de uma demanda.
    1. Recebe os dados corrigidos pelo analista.
    2. Atualiza a issue no GitHub (remove label antiga, adiciona nova, posta comentário).
    3. Salva a 'verdade' no Neo4j.
    """
    logger.info(f"Iniciando aprovação da issue #{issue_number} pelo analista.")

    try:
        # 1. Buscar detalhes originais da issue (para salvar no Neo4j)
        issue_details = await get_issue_details(issue_number)

        # 2. Atualizar o GitHub
        await update_issue_labels(
            issue_number=issue_number,
            add_labels=[LABEL_VALIDADO],
            remove_labels=[LABEL_AGUARDANDO_VALIDACAO],
        )

        # Monta o corpo do comentário final
        comment_body = f"""
## ✅ Validação Humana Concluída

Esta demanda foi revisada e aprovada por um analista.

---
**Dados Consolidados:**
- **Tipo Final:** {validated_data.tipo_solicitacao}
- **Prioridade Final:** {validated_data.prioridade}
- **Esforço Estimado:** {validated_data.esforco_estimado if validated_data.esforco_estimado else "N/A"} horas/PF

**RCMs Relacionadas:**
{", ".join(validated_data.rcms_relacionadas) if validated_data.rcms_relacionadas else "Nenhuma identificada."}

**Observações do Analista:**
{validated_data.comentarios_validacao if validated_data.comentarios_validacao else "Sem observações adicionais."}
"""
        await post_comment(issue_number, comment_body)

        logger.info(
            f"Issue #{issue_number} aprovada e atualizada no GitHub com sucesso."
        )

        # 3. Salvar no Neo4j
        await save_validated_demand_data(
            issue_number=issue_number,
            issue_title=issue_details["title"],
            issue_body=issue_details["body"],
            issue_html_url=issue_details["html_url"],
            validated_data=validated_data,
        )
        logger.info(f"Dados da Demanda #{issue_number} salvos no Neo4j.")

        return {
            "status": "success",
            "message": f"Validação da issue #{issue_number} aprovada com sucesso.",
            "issue_number": issue_number,
        }

    except Exception as e:
        logger.error(
            f"Erro ao aprovar validação da issue #{issue_number}: {e}", exc_info=True
        )
        # Tenta identificar erros específicos do PyGithub ou Neo4j, senão 500 genérico
        detail_message = f"Erro interno ao processar aprovação: {str(e)}"
        if "Not Found" in str(e):  # Erro comum do GitHub
            raise HTTPException(
                status_code=404,
                detail=f"Issue #{issue_number} não encontrada no GitHub.",
            )
        elif (
            "authentication" in str(e).lower() or "authorization" in str(e).lower()
        ):  # Erro comum de token
            detail_message = "Erro de autenticação/autorização com GitHub ou Neo4j. Verifique seus tokens."
        elif "Failed to establish connection" in str(e):  # Erro de conexão Neo4j
            detail_message = "Falha de conexão com o banco de dados Neo4j."

        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=detail_message
        )

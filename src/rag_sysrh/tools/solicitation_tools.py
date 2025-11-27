import logging
from typing import Optional, Type

from langchain_core.callbacks import CallbackManagerForToolRun
from langchain_core.tools import BaseTool
from pydantic import BaseModel, Field

from src.services.github_service import create_issue

logger = logging.getLogger(__name__)


class CreateSolicitationInput(BaseModel):
    title: str = Field(description="O título da solicitação. Deve ser claro e conciso.")
    description: str = Field(
        description="A descrição detalhada do problema ou solicitação."
    )
    priority: str = Field(
        description="A prioridade da solicitação (Baixa, Média, Alta).",
        default="Média",
    )
    solicitation_type: str = Field(
        description="O tipo da solicitação (Evolutiva, Corretiva, Dúvida, etc.).",
        default="Evolutiva",
    )


class CreateSolicitationTool(BaseTool):
    name: str = "create_solicitation"
    description: str = (
        "Use esta ferramenta para criar uma nova solicitação (issue) no sistema "
        "quando o usuário confirmar que deseja abrir um chamado. "
        "Requer título, descrição, prioridade e tipo."
    )
    args_schema: Type[BaseModel] = CreateSolicitationInput

    def _run(
        self,
        title: str,
        description: str,
        priority: str = "Média",
        solicitation_type: str = "Evolutiva",
        run_manager: Optional[CallbackManagerForToolRun] = None,
    ) -> str:
        """Use the tool synchronously."""
        raise NotImplementedError("Use _arun instead")

    async def _arun(
        self,
        title: str,
        description: str,
        priority: str = "Média",
        solicitation_type: str = "Evolutiva",
        run_manager: Optional[CallbackManagerForToolRun] = None,
    ) -> str:
        """Use the tool asynchronously."""
        try:
            logger.info(f"Creating solicitation: {title} ({solicitation_type})")

            # Formata o corpo da issue
            body = f"""
**Tipo:** {solicitation_type}
**Prioridade Sugerida:** {priority}

---
**Descrição:**
{description}

*(Criado via Chat Agent)*
"""
            issue_number = await create_issue(title, body)
            return (
                f"Solicitação criada com sucesso! Número: #{issue_number}. "
                f"Você pode acompanhar o status pelo painel de Governança."
            )
        except Exception as e:
            logger.error(f"Error creating solicitation: {e}")
            return f"Erro ao criar solicitação: {str(e)}"

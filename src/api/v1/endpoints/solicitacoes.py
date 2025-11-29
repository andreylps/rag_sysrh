import logging
from enum import Enum

from fastapi import APIRouter, BackgroundTasks, HTTPException
from pydantic import BaseModel, Field

# Ajuste os imports conforme a estrutura real do seu projeto
from src.rag_sysrh.analista_workflow import AnalistaWorkflow
from src.rag_sysrh.main import get_tools
from src.services.github_service import create_issue, get_repo_name, post_comment

router = APIRouter()
logger = logging.getLogger(__name__)


# --- 1. DEFINIÇÃO DOS ENUMS ---
class TipoSolicitacao(str, Enum):
    EVOLUTIVA = "Evolutiva"
    CORRETIVA = "Corretiva"
    OPERACAO = "Operação"
    GARANTIA = "Garantia"
    MIGRACAO = "Migração"
    TRANSF_CONHECIMENTO = "Transferência de Conhecimento"
    CORRECAO_DADOS = "Correção de Dados"
    # Legacy/Generic values
    INCIDENTE = "Incidente"
    MELHORIA = "Melhoria"
    NOVA_FUNCIONALIDADE = "Nova Funcionalidade"
    DUVIDA = "Dúvida"


class PrioridadeSugerida(str, Enum):
    BAIXA = "Baixa"
    MEDIA = "Média"
    ALTA = "Alta"


# --- 2. ATUALIZAÇÃO DO MODELO PYDANTIC ---
class SolicitacaoRequest(BaseModel):
    titulo: str = Field(..., min_length=5, max_length=100)
    descricao: str = Field(..., min_length=20)
    # Novos campos com valores padrão para facilitar testes se o front não enviar
    tipo_solicitacao: TipoSolicitacao = Field(
        default=TipoSolicitacao.EVOLUTIVA, description="Tipo da demanda."
    )
    prioridade_sugerida: PrioridadeSugerida = Field(
        default=PrioridadeSugerida.MEDIA,
        description="Prioridade sugerida pelo usuário.",
    )


async def processar_solicitacao_background(
    issue_id: int,
    descricao: str,
    # Recebe os novos campos para passar à IA
    tipo_solicitacao: str,
    prioridade_sugerida: str,
):
    """
    Executa a análise da IA em background e posta o resultado como comentário na Issue.
    """
    logger.info(f"Iniciando análise background para issue #{issue_id}")
    try:
        # Instancia o agente
        tools = get_tools()
        agente = AnalistaWorkflow(tools=tools)

        # --- ENRIQUECENDO O PROMPT PARA A IA ---
        # Passamos o tipo e prioridade sugeridos como contexto extra.
        contexto_extra = f"""
--- CONTEXTO ADICIONAL FORNECIDO PELO USUÁRIO ---
Tipo de Solicitação Declarado: {tipo_solicitacao}
Prioridade Sugerida pelo Usuário: {prioridade_sugerida}
--- FIM DO CONTEXTO ADICIONAL ---

{descricao}
"""
        # Executa a análise com o prompt enriquecido
        resultado = await agente.arun(contexto_extra, solicitacao_id=issue_id)

        # Formata o comentário em Markdown
        comentario = "## 🤖 Análise Automática de Requisitos\n\n"

        if resultado:
            # ... (Resto da formatação do comentário permanece igual)
            comentario += f"**Classificação:** {resultado.tipo_problema}\n"
            comentario += f"**Complexidade:** {resultado.complexidade}\n"
            comentario += f"**Nível de Esforço:** {resultado.nivel_esforco}\n\n"

            comentario += "### 📋 Resumo\n"
            comentario += f"{resultado.resumo_problema}\n\n"

            comentario += "### 🔍 Diagnóstico Técnico\n"
            comentario += f"{resultado.diagnostico}\n\n"

            comentario += "### 💡 Solução Sugerida\n"
            comentario += f"{resultado.solucao_sugerida}\n\n"

            if resultado.detalhes_evolutiva:
                comentario += "### 📊 Estimativas (Evolutiva)\n"
                comentario += f"- **Pontos de Função:** {resultado.detalhes_evolutiva.estimativa_pontos_funcao}\n"
                comentario += f"- **Prazo Estimado:** {resultado.detalhes_evolutiva.prazo_dias_uteis} dias úteis\n"
                comentario += f"- **Entrega Prevista:** {resultado.detalhes_evolutiva.data_prevista_entrega}\n"
        else:
            comentario += "⚠️ **Aviso:** A análise retornou vazia ou inconclusiva."

        # --- 4. ATUALIZAÇÃO DE LABELS ---
        # Lógica de Bifurcação de Fluxo:
        # 1. Evolutiva/Melhoria -> Fluxo Lento (RCM) -> 'status:aguardando-validacao-rcm' (Já adicionado pelo workflow)
        # 2. Outros (Corretiva, Operação, Dúvida) -> Fluxo Rápido (Fast Track) -> 'status:aguardando-liberacao-dev'
        
        label_to_add = "status:aguardando-liberacao-dev" # Default Fast Track
        
        if resultado and resultado.tipo_solicitacao:
             tipo_lower = resultado.tipo_solicitacao.lower()
             if "evoluti" in tipo_lower or "melhoria" in tipo_lower:
                 # Se for evolutiva, o workflow já cuidou da label de RCM.
                 # Não adicionamos nada aqui para evitar conflito.
                 label_to_add = None
        
        if label_to_add:
            from src.services.github_service import update_issue_labels
            await update_issue_labels(
                issue_number=issue_id, add_labels=[label_to_add]
            )

        # Posta o comentário no GitHub
        await post_comment(issue_id, comentario)
        logger.info(f"Análise postada com sucesso na issue #{issue_id}")

    except Exception as e:
        # ... (Tratamento de erro permanece igual)
        logger.error(f"Erro no processamento background da issue #{issue_id}: {e}")
        erro_msg = f"⚠️ **Erro no Processamento da IA**\n\nOcorreu um erro ao tentar analisar esta solicitação:\n`{str(e)}`"
        await post_comment(issue_id, erro_msg)


@router.post("/")
async def criar_solicitacao(
    request: SolicitacaoRequest, background_tasks: BackgroundTasks
):
    """
    Cria uma nova solicitação.
    1. Cria a Issue no GitHub com metadados.
    2. Retorna o ID da Issue.
    3. Dispara a análise da IA em background com contexto extra.
    """
    try:
        # 1. Criar Issue no GitHub com um corpo mais rico
        logger.info(
            f"Recebendo solicitação: {request.titulo} ({request.tipo_solicitacao})"
        )

        # Formata o corpo da issue para incluir os novos campos no topo
        corpo_issue = f"""
**Tipo:** {request.tipo_solicitacao.value}
**Prioridade Sugerida:** {request.prioridade_sugerida.value}

---
**Descrição:**
{request.descricao}
"""
        # Chama o serviço do GitHub com o corpo formatado
        issue_id = await create_issue(request.titulo, corpo_issue)

        # 2. Agendar processamento background passando os novos dados
        background_tasks.add_task(
            processar_solicitacao_background,
            issue_id=issue_id,
            descricao=request.descricao,
            tipo_solicitacao=request.tipo_solicitacao.value,
            prioridade_sugerida=request.prioridade_sugerida.value,
        )

        return {
            "status": "recebido",
            "mensagem": "Solicitação registrada com sucesso. A análise da IA será postada na Issue em breve.",
            "issue_id": issue_id,
            # Helper link (certifique-se que get_repo_name() retorna o formato correto 'dono/repo')
            "link_issue": f"https://github.com/{get_repo_name()}/issues/{issue_id}",
        }
    except Exception as e:
        logger.error(f"Erro ao criar solicitação: {e}")
        # Tenta pegar uma mensagem de erro mais limpa se for um erro do GitHub
        erro_detalhe = str(e)
        if hasattr(e, "response") and e.response is not None:
            try:
                erro_detalhe = e.response.json().get("message", str(e))
            except:  # noqa: E722
                pass

        raise HTTPException(
            status_code=500, detail=f"Erro ao criar issue: {erro_detalhe}"
        )

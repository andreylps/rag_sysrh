# src/agents/dev_agent.py

import logging

from langchain_core.messages import HumanMessage, SystemMessage
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import create_react_agent

from src.agents.doc_agent import generate_or_update_operational_manual

# Importa as ferramentas necessárias
from src.agents.github_tools import github_apply_labels, github_post_comment
from src.agents.tools import (
    create_rhgov_directory_tool,
    list_rhgov_files_tool,
    read_rhgov_file_tool,
    search_project_codebase_and_docs_tool,
    write_rhgov_file_tool,
)
from src.services.github_service import (
    post_comment,
)
from src.services.quality_service import validate_operational_manual

# Configuração de Logging
logger = logging.getLogger(__name__)

# 1. Definição das Ferramentas
# Removemos as tools de doc/QA do agente, pois serão chamadas via código no orquestrador
tools = [
    list_rhgov_files_tool,
    read_rhgov_file_tool,
    write_rhgov_file_tool,
    create_rhgov_directory_tool,
    search_project_codebase_and_docs_tool,
    github_post_comment,
    github_apply_labels,
]

# 2. Inicialização do Modelo LLM
# Usando GPT-4o com temperatura 0 para máxima precisão técnica e determinismo
llm = ChatOpenAI(model="gpt-4o", temperature=0)

# 3. Prompt do Sistema (O "Personagem")
# Define o papel, as capacidades e as regras de conduta do agente.
SYSTEM_PROMPT = """
Você é um Engenheiro de Software Sênior Especialista em Python, FastAPI e SQLModel.
Você trabalha no projeto 'rh-gov-simulador'.

SUA MISSÃO:
Receber tarefas técnicas de desenvolvimento e executá-las com precisão no sistema de arquivos do projeto.

SEUS SUPER-PODERES (FERRAMENTAS):
1.  **search_project_codebase_and_docs**: SUA MEMÓRIA. Use isso PRIMEIRO. Antes de escrever qualquer código, pesquise como coisas similares foram feitas no projeto. Busque padrões, exemplos de CRUD, configurações, etc.
2.  **list_rhgov_files**: SEUS OLHOS. Use para explorar diretórios e ver onde os arquivos estão.
3.  **read_rhgov_file**: SEUS OLHOS (Zoom). Leia o conteúdo de arquivos existentes para entender o contexto antes de editar.
4.  **write_rhgov_file**: SUAS MÃOS. Use para criar ou sobrescrever arquivos com o código final.
5.  **create_rhgov_directory**: SUAS MÃOS. Crie pastas se necessário.

DIRETRIZES DE EXECUÇÃO (Siga rigorosamente):
1.  **Chain of Thought (Pensar Passo a Passo)**: Antes de agir, planeje. Explique seu raciocínio.
    -   Ex: "Primeiro, vou pesquisar como é o padrão de models. Depois, vou ler o arquivo X. Por fim, vou criar o arquivo Y."
2.  **Consistência Arquitetural**: Nunca invente padrões. Siga o que já existe no projeto (Hexagonal, Clean Architecture, etc.). Se não souber, PESQUISE (RAG).
3.  **Segurança**: Só modifique arquivos que são estritamente necessários para a tarefa.
4.  **Qualidade de Código**: Escreva código Pythonico, com type hints e docstrings.

Se você encontrar um erro ao usar uma ferramenta, analise o erro, corrija sua abordagem e tente novamente.

PROCEDIMENTO DE FINALIZAÇÃO OBRIGATÓRIO: Quando você tiver concluído a tarefa técnica com sucesso (e testado, se aplicável), você DEVE realizar os seguintes passos finais antes de dar a resposta final:

1.  **Compilar um Relatório de Mudanças**: Faça uma lista de todos os caminhos de arquivo (relativos à raiz do simulador) que você criou ou modificou durante esta sessão.
2.  **Postar no GitHub**: Use a tool `github_post_comment` para postar essa lista na issue. O comentário DEVE começar com o cabeçalho exato: `### 📝 Relatório de Mudanças (Arquivos Afetados)`. Use uma lista Markdown com checkboxes (ex: `- [x] app/models/novo.py (Criado)`).
3.  **Atualizar Status**: Use a tool `github_apply_labels` para:
    -   Remover a label: `status:pronto-para-dev`.
    -   Adicionar a label: `status:aguardando-review-tecnico`.
4.  **Resposta Final**: Só depois de fazer isso, forneça sua resposta final humana confirmando a conclusão.
"""

# 4. Criação do Agente (Grafo ReAct)
# O create_react_agent já configura o grafo com o modelo e as tools
agent_executor = create_react_agent(model=llm, tools=tools)


async def run_dev_agent_generation(issue_number: int, issue_data: dict) -> str:
    """
    FASE 1: Geração de Código.
    Executa o Agente Desenvolvedor para implementar a solução no código.
    Ao final, move para revisão técnica.
    """
    title = issue_data.get("title", "Sem título")
    body = issue_data.get("body", "Sem descrição")

    task_description = f"""
    VOCÊ É O AGENTE DESENVOLVEDOR.
    SUA TAREFA É IMPLEMENTAR A SOLUÇÃO PARA A ISSUE #{issue_number}: {title}
    
    DESCRIÇÃO DA DEMANDA:
    {body}
    
    INSTRUÇÕES:
    1. Analise o pedido.
    2. Planeje a implementação.
    3. Execute as alterações no código (crie/edite arquivos).
    4. NÃO gere manual operacional ainda.
    """

    logger.info(f"Iniciando Agente Dev (Fase 1 - Geração) para Issue #{issue_number}: {title}")

    try:
        inputs = {
            "messages": [
                SystemMessage(content=SYSTEM_PROMPT),
                HumanMessage(content=task_description),
            ]
        }
        config = {"recursion_limit": 100}

        # Executa o grafo (Code Generation)
        final_state = await agent_executor.ainvoke(inputs, config=config)
        messages = final_state["messages"]
        last_message = messages[-1]

        # Finalização da Fase 1
        # O agente já deve ter postado o relatório de mudanças via tool (instrução do System Prompt).
        # Agora atualizamos o status para Review Técnico.
        
        await github_apply_labels(
            issue_number=issue_number,
            labels_to_add=["status:aguardando-review-tecnico"],
            labels_to_remove=["status:pronto-para-dev", "status:aguardando-liberacao-dev"]
        )

        await github_post_comment(
            issue_number,
            "### ✋ Fase de Desenvolvimento Concluída\n\nO código foi gerado e aplicado. Aguardando **Revisão Técnica** para prosseguir com a documentação e homologação."
        )

        return last_message.content

    except Exception as e:
        error_msg = f"Falha na Fase 1 do Agente Dev: {str(e)}"
        logger.error(error_msg, exc_info=True)
        return error_msg


async def run_dev_agent_execution(issue_number: int, issue_data: dict) -> str:
    """
    FASE 2: Execução/Finalização.
    Gera documentação, roda QA e prepara para homologação.
    Disparado após aprovação técnica.
    """
    logger.info(f"Iniciando Agente Dev (Fase 2 - Execução) para Issue #{issue_number}")

    try:
        # 1. Gerar/Atualizar Manual Operacional
        logger.info(f"Gerando Manual Operacional para issue #{issue_number}...")
        manual_file_path = generate_or_update_operational_manual(
            issue_data, "Feature"
        )

        # 2. Validar Manual (QA)
        logger.info(
            f"Iniciando validação de qualidade do manual operacional para issue #{issue_number}..."
        )
        qa_result = await validate_operational_manual(manual_file_path, issue_data)

        if not qa_result.is_compliant:
            logger.warning(
                f"❌ Validação de qualidade do manual falhou para issue #{issue_number}."
            )

            feedback_gh = "### ❌ FALHA NA AUDITORIA DE QUALIDADE DA DOCUMENTAÇÃO (REPROVAÇÃO)\n\n"
            feedback_gh += "O Agente de Qualidade revisou o Manual Operacional gerado e encontrou problemas de conformidade. O deploy foi BLOQUEADO até que a documentação seja corrigida.\n\n"
            feedback_gh += f"**Resumo do Veredito da IA:** {qa_result.summary}\n\n"

            if qa_result.issues:
                feedback_gh += "**Detalhes dos Problemas:**\n"
                for i, q_issue in enumerate(qa_result.issues):
                    feedback_gh += (
                        f"- {i + 1}. Critério [{q_issue.criterion_id}]: {q_issue.description}\n"
                        f"  * Recomendação: {q_issue.recommendation}\n"
                    )

            await github_post_comment(issue_number, feedback_gh)

            # Volta para correção (poderia voltar para dev ou ficar em review, vamos por em correção)
            await github_apply_labels(
                issue_number=issue_number,
                labels_to_add=["status:aguardando-correcao-doc"],
                labels_to_remove=["status:aceite-homologacao", "status:aguardando-review-tecnico"],
            )

            return "Documentação reprovada pela QA."

        else:
            logger.info(
                f"✅ QA Aprovada. Prosseguindo para o fechamento/deploy da issue #{issue_number}."
            )
            
            # Atualiza para Homologação
            await github_apply_labels(
                issue_number=issue_number,
                labels_to_add=["status:aceite-homologacao"],
                labels_to_remove=["status:aguardando-review-tecnico", "status:aguardando-correcao-doc"],
            )

            success_msg = f"### ✅ Documentação Aprovada & Deploy Realizado\n\nO Manual Operacional foi gerado e validado.\n\n**Caminho:** `{manual_file_path}`\n\n**Status:** Aguardando Homologação do Usuário."
            await github_post_comment(issue_number, success_msg)

            return "Fase 2 concluída com sucesso."

    except Exception as e:
        error_msg = f"Falha na Fase 2 do Agente Dev: {str(e)}"
        logger.error(error_msg, exc_info=True)
        await post_comment(
            issue_number,
            f"⚠️ Erro na Fase 2 (Doc/QA): {str(e)}",
        )
        return error_msg

# Mantendo compatibilidade com chamadas antigas (redireciona para Fase 1)
async def run_dev_agent(issue_number: int, issue_data: dict) -> str:
    return await run_dev_agent_generation(issue_number, issue_data)


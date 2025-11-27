import logging

from fastapi import APIRouter, HTTPException

from src.schemas.rcm import ClientActionDTO, ClientActionEnum, RCMApprovalDTO
from src.services.github_service import post_comment, update_issue_labels

# Configuração de Logging
logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/{issue_number}/approve", status_code=200)
async def approve_rcm(issue_number: int, approval_data: RCMApprovalDTO):
    """
    Aprova o Rascunho de RCM e move a issue para aprovação do cliente.
    """
    try:
        logger.info(f"Aprovando RCM para issue #{issue_number}...")

        # 1. Construir o corpo do comentário final
        comment_body = f"""## ✅ RCM Validada pelo Analista

A seguinte Memória de Cálculo (RCM) foi revisada e aprovada para envio ao cliente:

---
{approval_data.final_rcm_text}
---

**Próximo Passo:** Aguardando aprovação formal do cliente.
"""
        if approval_data.analyst_comments:
            comment_body += (
                f"\n**Observações do Analista:**\n{approval_data.analyst_comments}"
            )

        try:
            # 0. Gerar RCM Física (DOCX)
            from src.rag_sysrh.services.document_service import DocumentService

            doc_service = DocumentService()
            doc_service.generate_simple_rcm_docx(
                issue_number, approval_data.final_rcm_text
            )

            # 1. Postar o comentário final na issue
            await post_comment(issue_number=issue_number, body=comment_body)

            # 2. Atualizar Labels
            # Remove 'aguardando-validacao-rcm' e adiciona 'aguardando-aprovacao-cliente'
            await update_issue_labels(
                issue_number=issue_number,
                add_labels=["status:aguardando-aprovacao-cliente"],
                remove_labels=["status:aguardando-validacao-rcm"],
            )

            # 3. Enviar E-mail para o Cliente (se fornecido)
            email_sent = False
            email_status = "not_configured"  # sent, simulated, error, not_configured

            if approval_data.client_email:
                from src.services.email_service import EmailService

                email_service = EmailService()
                # Busca título da issue para o e-mail (poderia vir no DTO, mas vamos buscar rápido ou passar vazio)
                # Idealmente o frontend manda o título, mas vamos assumir que o serviço pega ou usamos genérico
                email_sent, email_status = email_service.send_rcm_approval_link(
                    to_email=approval_data.client_email,
                    issue_number=issue_number,
                    issue_title=f"Demanda #{issue_number}",  # Simplificação
                )

            return {
                "status": "success",
                "message": "RCM aprovada com sucesso.",
                "email_status": email_status,
            }

        except Exception as e:
            import traceback

            logger.error(f"Erro ao processar aprovação: {e}")
            logger.error(traceback.format_exc())
            raise HTTPException(
                status_code=500, detail=f"Erro ao processar aprovação: {str(e)}"
            )

    except Exception as e:
        logger.error(f"Erro ao aprovar RCM: {e}")
        raise HTTPException(
            status_code=500, detail=f"Erro ao processar aprovação de RCM: {str(e)}"
        )


@router.post("/{issue_number}/client-action", status_code=200)
async def client_action(issue_number: int, action_data: ClientActionDTO):
    """
    Registra a decisão do cliente sobre a RCM (Aprovar ou Rejeitar).
    """
    try:
        logger.info(
            f"Recebendo ação do cliente para issue #{issue_number}: {action_data.action}"
        )

        if action_data.action == ClientActionEnum.APPROVE:
            # --- CENÁRIO: APROVAÇÃO ---
            comment_body = "🤝 **RCM Aprovada pelo Cliente**\n\nOrçamento e escopo aceitos. Autorizado o início do desenvolvimento."

            await post_comment(issue_number=issue_number, body=comment_body)

            await update_issue_labels(
                issue_number=issue_number,
                remove_labels=["status:aguardando-aprovacao-cliente"],
                add_labels=["status:pronto-para-dev"],
            )

            return {
                "message": f"RCM aprovada pelo cliente. Issue #{issue_number} movida para desenvolvimento."
            }

        elif action_data.action == ClientActionEnum.REJECT:
            # --- CENÁRIO: REJEIÇÃO COM REVISÃO AUTOMÁTICA ---

            # 1. Notifica a rejeição
            comment_body = f"⚠️ **RCM Devolvida pelo Cliente**\n\n**Motivo:** {action_data.client_comments}"
            await post_comment(issue_number=issue_number, body=comment_body)

            # 2. Aciona o Agente para Revisão
            try:
                from src.rag_sysrh.analista_workflow import AnalistaWorkflow
                from src.rag_sysrh.main import get_tools
                from src.services.github_service import get_issue_details

                # Instancia o agente (pode ser otimizado com injeção de dependência)
                agent = AnalistaWorkflow(tools=get_tools())

                # Busca o texto atual do RCM (última versão validada ou rascunho)
                # Reutiliza a lógica de extração que já existe no endpoint 'details'
                # Mas como estamos dentro do endpoint, podemos chamar get_issue_details
                issue_details = await get_issue_details(issue_number)

                # Tenta pegar a versão validada primeiro (que foi enviada ao cliente)
                current_rcm_text = issue_details.get(
                    "rcm_draft"
                )  # get_issue_details já faz a lógica de prioridade

                if current_rcm_text:
                    # Executa a revisão
                    revised_rcm = await agent.processar_rejeicao(
                        rcm_text=current_rcm_text,
                        client_feedback=action_data.client_comments,
                    )

                    # Posta o novo rascunho revisado
                    revision_comment = (
                        f"## 🤖 RCM Revisada pela IA (Pós-Feedback)\n\n{revised_rcm}"
                    )
                    await post_comment(issue_number=issue_number, body=revision_comment)

                    # Atualiza labels
                    await update_issue_labels(
                        issue_number=issue_number,
                        remove_labels=["status:aguardando-aprovacao-cliente"],
                        add_labels=[
                            "status:aguardando-validacao-rcm",
                            "status:rcm-rejeitada",
                            "status:rcm-revisada-ia",
                        ],
                    )

                    return {
                        "message": f"RCM rejeitada e revisada pela IA. Issue #{issue_number} devolvida para validação."
                    }
                else:
                    # Fallback se não achar texto para revisar
                    await update_issue_labels(
                        issue_number=issue_number,
                        remove_labels=["status:aguardando-aprovacao-cliente"],
                        add_labels=[
                            "status:aguardando-validacao-rcm",
                            "status:rcm-rejeitada",
                        ],
                    )
                    return {
                        "message": "RCM rejeitada, mas não foi possível revisar automaticamente (texto base não encontrado)."
                    }

            except Exception as e:
                # Fallback em caso de erro no agente
                print(f"Erro na revisão automática: {e}")
                await update_issue_labels(
                    issue_number=issue_number,
                    remove_labels=["status:aguardando-aprovacao-cliente"],
                    add_labels=[
                        "status:aguardando-validacao-rcm",
                        "status:rcm-rejeitada",
                    ],
                )
                return {
                    "message": f"RCM rejeitada. Erro na revisão automática: {str(e)}"
                }

    except Exception as e:
        logger.error(f"Erro ao processar ação do cliente: {e}")
        raise HTTPException(
            status_code=500, detail=f"Erro ao processar ação do cliente: {str(e)}"
        )


@router.get("/{issue_number}/details", response_model=dict)
async def get_rcm_details(issue_number: int):
    """
    Retorna detalhes estruturados do RCM para o Portal do Cliente (Dashboard).
    Inclui métricas extraídas e histórico de aprovações.
    """
    try:
        import re

        from src.services.github_service import get_issue_details

        # 1. Buscar dados da Issue
        issue = await get_issue_details(issue_number)

        # 2. Extrair RCM Aprovado (ou Draft se não houver aprovado)
        rcm_text = issue.get("rcm_draft", "")
        comments = issue.get("comments", [])

        # Tenta achar o RCM aprovado nos comentários
        approved_comment = next(
            (
                c
                for c in reversed(comments)
                if "## ✅ RCM Validada pelo Analista" in c["body"]
            ),
            None,
        )
        if approved_comment:
            rcm_text = approved_comment["body"]

        # 3. Extrair Métricas do Texto (Regex mais robusto)
        # Tenta capturar:
        # **Pontos de Função:** 10
        # **Estimativa de Pontos de Função (PF):** 12
        # Pontos de Função: 10
        # - Pontos de Função: 10
        pf_match = re.search(
            r"(?:Pontos de Função|PF)[^\d\n]*[:\s]*\*+?\s*([\d\.,]+)",
            rcm_text,
            re.IGNORECASE,
        )
        prazo_match = re.search(
            r"(?:Prazo Estimado|Prazo)[^\d\n]*[:\s]*\*+?\s*(\d+)",
            rcm_text,
            re.IGNORECASE,
        )

        pontos_funcao = float(pf_match.group(1).replace(",", ".")) if pf_match else 0.0
        prazo_dias = int(prazo_match.group(1)) if prazo_match else 0
        custo_total = pontos_funcao * 1000.00  # Exemplo: R$ 1000 por PF (Placeholder)

        # 4. Construir Histórico
        history = []
        for c in comments:
            body = c["body"]
            # user = c["user"]  <-- Removed unused variable
            date = c["created_at"]

            if "## ✅ RCM Validada pelo Analista" in body:
                history.append(
                    {
                        "date": date,
                        "user": "Analista",  # Ou user real
                        "action": "Validado pelo Analista",
                        "comments": "RCM liberada para aprovação do cliente.",
                    }
                )
            elif "⚠️ **RCM Devolvida pelo Cliente**" in body:
                reason = (
                    body.split("**Motivo:**")[1].strip()
                    if "**Motivo:**" in body
                    else ""
                )
                history.append(
                    {
                        "date": date,
                        "user": "Cliente",
                        "action": "Rejeitado pelo Cliente",
                        "comments": reason,
                    }
                )
            elif "🤝 **RCM Aprovada pelo Cliente**" in body:
                history.append(
                    {
                        "date": date,
                        "user": "Cliente",
                        "action": "Aprovado pelo Cliente",
                        "comments": "Orçamento e escopo aceitos.",
                    }
                )

        return {
            "issue_number": issue["number"],
            "title": issue["title"],
            "status": issue["labels"][0] if issue["labels"] else "Unknown",
            "pontos_funcao": pontos_funcao,
            "prazo_dias": prazo_dias,
            "custo_total": custo_total,
            "rcm_text": rcm_text,
            "history": history,
        }

    except Exception as e:
        logger.error(f"Erro ao buscar detalhes do RCM: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{issue_number}/download")
async def download_rcm(issue_number: int):
    """
    Retorna o arquivo DOCX do RCM para download.
    """
    try:
        from fastapi.responses import FileResponse

        from src.rag_sysrh.services.document_service import DocumentService

        doc_service = DocumentService()

        # Tenta recuperar o arquivo registrado
        try:
            file_path = doc_service.get_rcm_file(issue_number)
        except FileNotFoundError:
            # Se não achar (reinício do servidor perde o mapa em memória),
            # tenta regenerar ou buscar em pasta padrão se implementarmos persistência real.
            # Por enquanto, vamos regenerar on-the-fly usando o texto da issue.
            from src.services.github_service import get_issue_details

            issue = await get_issue_details(issue_number)

            # Lógica de extração repetida (idealmente refatorar para func auxiliar)
            rcm_text = issue.get("rcm_draft", "")
            comments = issue.get("comments", [])
            approved_comment = next(
                (
                    c
                    for c in reversed(comments)
                    if "## ✅ RCM Validada pelo Analista" in c["body"]
                ),
                None,
            )
            if approved_comment:
                rcm_text = approved_comment["body"]

            if not rcm_text:
                raise HTTPException(
                    status_code=404, detail="RCM text not found to generate file."
                )

            # Gera e registra
            file_path_str = doc_service.generate_simple_rcm_docx(issue_number, rcm_text)
            file_path = doc_service.get_file_path(file_path_str)

        return FileResponse(
            path=file_path,
            filename=f"RCM_{issue_number}.docx",
            media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        )

    except Exception as e:
        logger.error(f"Erro ao baixar RCM: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/{issue_number}/download-memoria", status_code=200)
async def download_memoria_calculo(issue_number: int):
    """
    Retorna o arquivo XLSX da Memória de Cálculo para download.
    """
    try:
        from fastapi.responses import FileResponse

        from src.rag_sysrh.services.document_service import DocumentService

        doc_service = DocumentService()

        # Tenta recuperar o arquivo registrado ou gerar on-the-fly
        try:
            file_path = doc_service.get_memcalc_file(issue_number)
        except Exception:
            # Se não existir, gera um novo (com dados placeholder por enquanto,
            # ou futuramente extraídos da análise)
            file_path_str = doc_service.generate_memory_of_calculation_xlsx(
                issue_number
            )
            file_path = doc_service.get_file_path(file_path_str)

        return FileResponse(
            path=file_path,
            filename=f"Memoria_Calculo_{issue_number}.xlsx",
            media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        )

    except Exception as e:
        logger.error(f"Erro ao baixar Memória de Cálculo: {e}")
        raise HTTPException(status_code=500, detail=str(e))

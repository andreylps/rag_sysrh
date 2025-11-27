# src/api/v1/endpoints/webhook.py
import json
import logging

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException

from src.agents.dev_agent import run_dev_agent

# Importe seus runners de agentes (ajuste os caminhos se necessário)
from src.agents.triage_agent import run_triage_agent

# Importe a função de segurança corrigida
from src.api.security import verify_github_signature

# Configuração de Logging
logger = logging.getLogger(__name__)

router = APIRouter()


# Se no GitHub sua URL termina com /, mantenha a barra aqui: post("/")
# Se no GitHub sua URL NÃO termina com /, use vazio aqui: post("")
@router.post("/", status_code=202)
async def github_webhook(
    background_tasks: BackgroundTasks,
    # AQUI ESTÁ O SEGREDO: Recebe os bytes que a função de segurança retornou
    body_bytes: bytes = Depends(verify_github_signature),
):
    """
    Endpoint principal do Webhook do GitHub.
    Recebe os dados brutos já validados e dispara os agentes apropriados.
    """
    try:
        # Debug: Ver o que chegou
        logger.info(f"DEBUG (endpoint): Recebi {len(body_bytes)} bytes.")
        # logger.info(f"DEBUG Content: {body_bytes[:100]}")

        # 1. Decodifica os bytes
        decoded_body = body_bytes.decode("utf-8")

        # 2. Verifica se é form-urlencoded (padrão antigo do GitHub)
        if decoded_body.startswith("payload="):
            import urllib.parse

            # Remove 'payload=' e decodifica a URL
            decoded_body = urllib.parse.unquote_plus(decoded_body[8:])
            logger.info(
                "Detectado formato application/x-www-form-urlencoded. Payload extraído."
            )

        # 3. Converte para JSON
        payload = json.loads(decoded_body)

        # Lógica de roteamento de eventos
        action = payload.get("action")

        # --- CENÁRIO 1: Nova Issue (Dispara Triagem) ---
        if "issue" in payload and action == "opened":
            issue_number = payload["issue"]["number"]
            title = payload["issue"]["title"]
            body = payload["issue"]["body"]

            print(
                f"📨 Webhook: Nova Issue #{issue_number} recebida. Disparando Triagem."
            )

            # Descomente quando tiver o runner
            background_tasks.add_task(
                run_triage_agent, issue_number=issue_number, title=title, body=body
            )

            return {
                "status": "accepted",
                "message": f"Triage started for issue #{issue_number}",
            }

        # --- CENÁRIO 2: Label 'pronto-para-dev' (Dispara Fábrica) ---
        elif "issue" in payload and action == "labeled":
            label_name = payload.get("label", {}).get("name")
            if label_name == "status:pronto-para-dev":
                issue_number = payload["issue"]["number"]
                title = payload["issue"]["title"]
                body = payload["issue"]["body"]

                print(
                    f"🏭 Webhook: Gatilho da Fábrica na Issue #{issue_number}. Disparando Dev."
                )

                # Descomente quando tiver o runner
                background_tasks.add_task(
                    run_dev_agent, issue_number, {"title": title, "body": body}
                )

                return {
                    "status": "accepted",
                    "message": f"Dev factory started for issue #{issue_number}",
                }

        # Se for outro evento que não nos interessa (ex: issue editada, comentário)
        # print(f"ℹ️ Evento ignorado: {action}")
        return {"status": "ignored", "message": "Event type not handled."}

    except json.JSONDecodeError as e:
        print(f"❌ Erro ao decodificar JSON do corpo da requisição: {e}")
        # Se os bytes estiverem vazios ou não forem JSON válido
        raise HTTPException(status_code=400, detail="Invalid JSON body content")
    except Exception as e:
        print(f"❌ Erro inesperado ao processar webhook: {e}")
        raise HTTPException(
            status_code=500, detail="Internal server error processing webhook"
        )

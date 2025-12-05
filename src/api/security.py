# src/api/deps.py
import hashlib
import hmac
import os
from typing import Optional

from fastapi import Header, HTTPException, Request


async def verify_github_signature(
    request: Request, x_hub_signature_256: Optional[str] = Header(None)
) -> bytes:
    """
    Verifica a assinatura HMAC SHA-256 do webhook do GitHub.
    Lê o corpo da requisição, valida e o RETORNA para ser usado no endpoint.
    """
    secret = os.getenv("GITHUB_WEBHOOK_SECRET")

    if not secret:
        # Log de erro crítico no servidor
        print("❌ ERRO CRÍTICO: GITHUB_WEBHOOK_SECRET não configurado no .env")
        # Retorna erro genérico para quem chamou
        raise HTTPException(status_code=500, detail="Server misconfiguration.")

    if not x_hub_signature_256:
        print("⚠️ Tentativa de acesso ao webhook sem assinatura.")
        raise HTTPException(status_code=403, detail="Missing signature header.")

    # 1. LÊ O CORPO BRUTO UMA ÚNICA VEZ
    try:
        payload_body = await request.body()
        # Debug: descomente para ver se os dados estão chegando
        # print(f"DEBUG (deps): Li {len(payload_body)} bytes do corpo.")
    except Exception as e:
        print(f"❌ Erro ao ler corpo da requisição: {e}")
        raise HTTPException(status_code=400, detail="Could not read request body")

    # Calcula o HMAC SHA-256 esperado
    hash_object = hmac.new(
        secret.encode("utf-8"), msg=payload_body, digestmod=hashlib.sha256
    )
    expected_signature = f"sha256={hash_object.hexdigest()}"

    # Compara de forma segura
    if not hmac.compare_digest(expected_signature, x_hub_signature_256):
        print("⛔ Assinatura do webhook inválida! Possível tentativa de ataque.")
        raise HTTPException(status_code=403, detail="Invalid signature.")

    # 2. RETORNA OS BYTES LIDOS PARA O ENDPOINT PRINCIPAL
    return payload_body

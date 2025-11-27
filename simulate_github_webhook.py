# simulate_github_webhook.py
import hashlib
import hmac
import json
import os

import httpx
from dotenv import load_dotenv

# Carrega as variáveis de ambiente para obter o segredo
load_dotenv()

WEBHOOK_SECRET = os.getenv("GITHUB_WEBHOOK_SECRET")
API_URL = "http://localhost:8080/api/v1/webhook/"

if not WEBHOOK_SECRET:
    print("❌ Erro: GITHUB_WEBHOOK_SECRET não encontrado no .env")
    exit(1)

# Payload de exemplo simulando uma issue criada
# Vamos simular uma Evolutiva para ver o agente gerar RCM
payload_data = {
    "action": "opened",
    "issue": {
        "number": 1003,  # Número de teste E2E
        "title": "[E2E #1003] Criar Módulo de Departamentos",
        "body": "Precisamos de uma nova entidade 'Departamento' (id, nome, sigla) e vincular os servidores a ela. Criar os models e o CRUD básico.",
    },
    "repository": {"full_name": "seu-usuario/seu-repo-teste"},
    "sender": {"login": "teste-bot"},
}

# Converte o payload para string JSON (o GitHub envia assim)
payload_body = json.dumps(payload_data).encode("utf-8")

# Calcula a assinatura HMAC SHA-256
signature = hmac.new(
    key=WEBHOOK_SECRET.encode("utf-8"), msg=payload_body, digestmod=hashlib.sha256
).hexdigest()

# Headers necessários para a requisição
headers = {
    "Content-Type": "application/json",
    "X-Hub-Signature-256": f"sha256={signature}",
    "X-GitHub-Event": "issues",
}

print(f"🔄 Enviando simulação de webhook para: {API_URL}")
print(f"📦 Payload: Título='{payload_data['issue']['title']}'")

try:
    # Faz a requisição POST
    response = httpx.post(API_URL, content=payload_body, headers=headers, timeout=10.0)

    print(f"📡 Status da Resposta: {response.status_code}")
    print(f"📄 Corpo da Resposta: {response.text}")

    if response.status_code == 202:
        print(
            "\n✅ SUCESSO: Webhook aceito! O Agente de Triagem deve estar rodando em background."
        )
        print(
            "👉 Verifique os logs do seu backend (run_api.py) para ver a execução do agente."
        )
        print(
            "   Você deve ver o raciocínio do agente e as chamadas às tools do GitHub (post_comment, apply_labels)."
        )
    elif response.status_code == 403:
        print(
            "\n❌ FALHA: Assinatura rejeitada. Verifique se o GITHUB_WEBHOOK_SECRET no .env está correto."
        )
    else:
        print("\n⚠️ Resultado inesperado. Verifique o código do endpoint.")

except Exception as e:
    print(f"\n❌ Erro de conexão: {e}")
    print("Verifique se o backend está rodando em http://localhost:8080")

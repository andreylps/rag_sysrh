import requests

url = "http://localhost:8080/api/v1/rcm/1003/client-action"
payload = {"action": "approve"}
headers = {"Content-Type": "application/json"}

try:
    print("🚀 Enviando aprovação do cliente...")
    response = requests.post(url, json=payload, headers=headers)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")

    if response.status_code == 200:
        print(
            "✅ Cliente aprovou. Aguardando Agente Dev trabalhar (isso pode levar alguns segundos)..."
        )
        # O agente roda em background. Vamos esperar um pouco.
        # Na vida real, o webhook seria disparado pela mudança de label.
        # Como estamos mockando o GitHub, o endpoint client-action ATUALIZA a label.
        # MAS o webhook só é disparado se o GitHub chamar o webhook.
        # O endpoint client-action NÃO chama o webhook.
        # O webhook é chamado pelo GitHub quando algo muda.

        # PERIGO: Se eu não simular o webhook de "labeled: pronto-para-dev", o Dev Agent NÃO vai rodar!
        # O endpoint client-action apenas muda a label no "GitHub" (nosso mock).
        # Ele NÃO dispara o agente diretamente. Quem dispara é o webhook.

        # Então, após o client-action (que retorna 200), eu preciso MANUALMENTE simular o webhook
        # de "labeled" com a label "status:pronto-para-dev".
        pass

except Exception as e:
    print(f"Error: {e}")

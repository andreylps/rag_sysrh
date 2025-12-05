import json
import sys

import requests

# Tenta importar requests, se falhar avisa
try:
    import requests
except ImportError:
    print("Requests não instalado. Instale com 'pip install requests'")
    sys.exit(1)

url_base = "http://localhost:8081"
url_poc = f"{url_base}/api/v1/poc/generate"
url_health = f"{url_base}/"
payload = {
    "problema_contexto": "Teste de POC automatizado",
    "objetivo_principal": "Verificar se o endpoint está respondendo corretamente",
    "funcionalidades_desejadas": "Teste de sanidade",
    "kpis_sucesso": "Status 200",
    "prazo_restricoes": "Imediato",
}

print("--- Iniciando Teste de Verificação ---")
print(f"Target URL POC: {url_poc}")

# Check Health
try:
    print(f"Checking Health at {url_health}...")
    resp_health = requests.get(url_health, timeout=5)
    print(f"Health Status: {resp_health.status_code}")
except Exception as e:
    print(f"Health Check Failed: {e}")

print(f"Payload: {json.dumps(payload, indent=2)}")

try:
    response = requests.post(url_poc, json=payload, timeout=30)
    print("\n--- Resposta do Servidor ---")
    print(f"Status Code: {response.status_code}")
    try:
        print(f"JSON Response: {json.dumps(response.json(), indent=2)}")
    except:
        print(f"Raw Response: {response.text}")

    if response.status_code == 200:
        print("\n✅ SUCESSO: Endpoint acessível e funcionando.")
    else:
        print("\n❌ FALHA: Endpoint retornou erro.")

except requests.exceptions.ConnectionError:
    print(
        f"\n❌ ERRO DE CONEXÃO: Não foi possível conectar a {url_poc}. Verifique se o servidor está rodando."
    )
except Exception as e:
    print(f"\n❌ ERRO INESPERADO: {e}")

import requests

url = "http://localhost:8080/api/v1/rcm/1003/approve"
payload = {
    "final_rcm_text": "RCM Validada para o Módulo de Departamentos. Estimativa: 20 PF. Escopo: Criação de tabela e endpoints."
}
headers = {"Content-Type": "application/json"}

try:
    response = requests.post(url, json=payload, headers=headers)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
except Exception as e:
    print(f"Error: {e}")

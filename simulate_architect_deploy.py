import requests

url = "http://localhost:8080/api/v1/review/1003/deploy"
headers = {"Content-Type": "application/json"}

try:
    print("🚀 Enviando comando de Deploy (Arquiteto)...")
    response = requests.post(url, headers=headers)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")

    if response.status_code == 200:
        print("✅ Deploy realizado com sucesso! Issue fechada.")
    else:
        print("❌ Falha no deploy.")

except Exception as e:
    print(f"Error: {e}")

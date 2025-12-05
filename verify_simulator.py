import requests

endpoints = [
    "http://localhost:8001/api/v1/servidores/",
    "http://localhost:8001/api/v1/cargos/",
]

for url in endpoints:
    try:
        response = requests.get(url)
        print(f"{url}: {response.status_code}")
    except Exception as e:
        print(f"{url}: Failed - {e}")

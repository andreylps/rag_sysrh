import requests

# URL exata reportada pelo usuário (decodificada para requests lidar, ou forçada)
# Browser: ...?period=%C3%9Altimos%2030%20dias
# %C3%9A = Ú
# %20 = space

base_url = "http://127.0.0.1:8080/api/v1/dashboard/production"
params = {"period": "Últimos 30 dias"}

print(f"Testing {base_url} with params {params}")

try:
    response = requests.get(base_url, params=params)
    print(f"Status Code: {response.status_code}")
    print("Response Headers:", response.headers)
    print("Response Content:", response.text)
except Exception as e:
    print(f"Request failed: {e}")

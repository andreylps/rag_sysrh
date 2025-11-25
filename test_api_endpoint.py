import requests

try:
    response = requests.get(
        "http://127.0.0.1:8080/api/v1/dashboard/production?period=Últimos 30 dias"
    )
    if response.status_code == 200:
        data = response.json()
        print("Status: 200 OK")
        print(f"Is Real Data: {data.get('isRealData')}")
        print(f"OEE: {data.get('oee')}")
        print(f"Availability: {data.get('availability')}")
    else:
        print(f"Status: {response.status_code}")
        print(response.text)
except Exception as e:
    print(f"Error: {e}")

import json

import requests

BASE_URL = "http://127.0.0.1:8080/api/v1/dashboard"


def test_endpoint(name, url):
    print(f"\n--- Testing {name} ({url}) ---")
    try:
        response = requests.get(url)
        print(f"Status Code: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("Keys received:", list(data.keys()))
            # Check for critical keys that might crash frontend if missing
            if name == "Production":
                required = ["oee", "productionOverTime", "rejectionRanking"]
                for r in required:
                    if r not in data:
                        print(f"❌ MISSING KEY: {r}")
            elif name == "Billing":
                required = ["receitaTotal", "evolucaoFinanceira", "topClientes"]
                for r in required:
                    if r not in data:
                        print(f"❌ MISSING KEY: {r}")

            print("Sample Data:", json.dumps(data, indent=2)[:500] + "...")
        else:
            print("❌ ERROR RESPONSE:")
            print(response.text)
    except Exception as e:
        print(f"❌ EXCEPTION: {e}")


if __name__ == "__main__":
    test_endpoint("Production", f"{BASE_URL}/production?period=Últimos 30 dias")
    test_endpoint("Billing", f"{BASE_URL}/billing?period=Últimos 30 dias")

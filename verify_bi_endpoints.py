import requests

BASE_URL = "http://localhost:8080/api/v1/bi"


def test_strategic_analyze():
    print("Testing /strategic/analyze...")
    try:
        res = requests.post(
            f"{BASE_URL}/strategic/analyze",
            json={"period": "30d", "team": "Todos", "client": "Todos"},
        )
        if res.status_code == 200:
            data = res.json()
            keys = [
                "kpis",
                "trend",
                "bottlenecks",
                "rejections",
                "financials",
                "narrative",
            ]
            missing = [k for k in keys if k not in data]
            if missing:
                print(f"FAILED: Missing keys in strategic response: {missing}")
            else:
                print("SUCCESS: Strategic analysis structure is correct.")
                print(f"Narrative keys: {data['narrative'].keys()}")
        else:
            print(f"FAILED: Status code {res.status_code}")
            print(res.text)
    except Exception as e:
        print(f"ERROR: {e}")


def test_billing_report():
    print("\nTesting /billing/report...")
    try:
        res = requests.get(f"{BASE_URL}/billing/report")
        if res.status_code == 200:
            data = res.json()
            keys = ["summary", "chart_data", "profitability_data", "comparison"]
            missing = [k for k in keys if k not in data]
            if missing:
                print(f"FAILED: Missing keys in billing response: {missing}")
            else:
                print("SUCCESS: Billing report structure is correct.")
        else:
            print(f"FAILED: Status code {res.status_code}")
            print(res.text)
    except Exception as e:
        print(f"ERROR: {e}")


if __name__ == "__main__":
    test_strategic_analyze()
    test_billing_report()

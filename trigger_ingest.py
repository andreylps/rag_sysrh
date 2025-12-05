import requests

base_url = "http://localhost:8001/api/v1/knowledge"

paths = ["/manuals", "/manuals/", "/ingest", "/ingest/"]

for path in paths:
    full_url = f"{base_url}{path}"
    print(f"Testing {full_url}...")

    # Try GET
    try:
        resp = requests.get(full_url)
        print(f"  GET: {resp.status_code}")
    except Exception as e:
        print(f"  GET Error: {e}")

    # Try POST
    try:
        resp = requests.post(full_url, json={"manuals": [], "system_data": True})
        print(f"  POST: {resp.status_code}")
        if resp.status_code == 200:
            print(f"  SUCCESS: {resp.text}")
    except Exception as e:
        print(f"  POST Error: {e}")
    print("-" * 20)

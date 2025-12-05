import json

import requests

url = "http://localhost:8080/api/v1/dashboard/production"

try:
    response = requests.get(url)
    if response.status_code == 200:
        data = response.json()
        backlog = data.get("panel_demand", {}).get("backlog_by_team", [])
        print("Backlog by Team:")
        print(json.dumps(backlog, indent=2))
    else:
        print(f"Error: {response.status_code} - {response.text}")
except Exception as e:
    print(f"Exception: {e}")

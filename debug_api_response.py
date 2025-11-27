import json

import requests

BASE_URL = "http://localhost:8080/api/v1"


def check_schedule():
    print("--- Checking Schedule ---")
    try:
        response = requests.get(f"{BASE_URL}/audit/schedule")
        print(f"GET {BASE_URL}/audit/schedule | Status: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"Count: {len(data)}")
            if data:
                print(f"Sample: {json.dumps(data[0])}")
        else:
            print(f"Error: {response.text}")
    except Exception as e:
        print(f"Exception: {e}")


if __name__ == "__main__":
    check_schedule()

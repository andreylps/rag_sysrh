import requests


def verify_history():
    url = "http://localhost:8080/api/v1/validacao/history"
    try:
        response = requests.get(url)
        if response.status_code == 200:
            issues = response.json()
            found = False
            for issue in issues:
                if issue["number"] == 38:
                    print("✅ Issue #38 found in history!")
                    print(f"Title: {issue['title']}")
                    print(f"State: {issue['state']}")
                    found = True
                    break

            if not found:
                print("❌ Issue #38 NOT found in history.")
                print("Issues found:", [i["number"] for i in issues])
        else:
            print(f"Error: API returned status {response.status_code}")
            print(response.text)
    except Exception as e:
        print(f"Error calling API: {e}")


if __name__ == "__main__":
    verify_history()

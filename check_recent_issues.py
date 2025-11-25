import os
import sys

sys.path.append(os.path.join(os.path.dirname(__file__), "src"))
from services.github_service import get_github_client, get_repo_name


def check():
    print("Checking recent issues...")
    try:
        g = get_github_client()
        repo = g.get_repo(get_repo_name())
        for issue in repo.get_issues(state="open")[:5]:
            print(f"#{issue.number}: {issue.title}")
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    check()

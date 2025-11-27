import os
import sys

from dotenv import load_dotenv

# Add project root to path
sys.path.append(os.getcwd())

# Load env vars
load_dotenv()

from src.services.github_service import get_github_client, get_repo_name


def main():
    try:
        g = get_github_client()
        repo_name = get_repo_name()
        print(f"Repo: {repo_name}")
        repo = g.get_repo(repo_name)
        issue = repo.get_issue(22)

        print(f"Issue #{issue.number}")
        print(f"Title: {issue.title}")
        print(f"State: {issue.state}")
        print(f"Labels: {[l.name for l in issue.labels]}")
        print(f"Closed at: {issue.closed_at}")

    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    main()

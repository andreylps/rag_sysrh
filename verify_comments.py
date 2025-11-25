import os
import sys

sys.path.append(os.path.join(os.path.dirname(__file__), "src"))
from services.github_service import get_github_client, get_repo_name


def check(issue_id):
    print(f"Checking comments for Issue #{issue_id}...")
    try:
        g = get_github_client()
        repo = g.get_repo(get_repo_name())
        issue = repo.get_issue(issue_id)
        comments = list(issue.get_comments())
        print(f"Issue #{issue_id} has {len(comments)} comments.")
        for c in comments:
            print(f"--- Comment ---\n{c.body[:200]}...")
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    check(5)

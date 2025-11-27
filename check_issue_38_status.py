import asyncio
import os

from github import Github


async def check_issue():
    token = os.getenv("GITHUB_TOKEN")
    if not token:
        # Try to read from .env manually if not loaded
        try:
            with open(".env", "r") as f:
                for line in f:
                    if line.startswith("GITHUB_TOKEN="):
                        token = line.split("=")[1].strip()
                        break
        except:
            pass

    if not token:
        print("GITHUB_TOKEN not found.")
        return

    g = Github(token)
    repo_name = "andreylps/rag_sysrh"

    try:
        repo = g.get_repo(repo_name)
        issue = repo.get_issue(38)

        print(f"Issue #{issue.number}: {issue.title}")
        print(f"State: {issue.state}")
        print("Labels:")
        for label in issue.labels:
            print(f" - {label.name}")

    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    asyncio.run(check_issue())

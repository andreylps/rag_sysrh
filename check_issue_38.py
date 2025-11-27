import asyncio
import os

from github import Github

# Mocking the service to avoid complex imports, just using PyGithub directly
# assuming GITHUB_TOKEN is in env or I can read it from .env if needed
# But since I am in the environment, I can try to import the service if possible,
# or just use the token from the environment variable.


async def check_issue():
    token = os.getenv("GITHUB_TOKEN")
    if not token:
        print("GITHUB_TOKEN not found in env.")
        return

    g = Github(token)
    repo_name = (
        "andreylps/rag_sysrh"  # Assuming this is the repo based on previous context
    )

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
    # Load env vars if needed (simple way)
    if not os.getenv("GITHUB_TOKEN"):
        # Try to read from .env manually if not loaded
        try:
            with open(".env", "r") as f:
                for line in f:
                    if line.startswith("GITHUB_TOKEN="):
                        os.environ["GITHUB_TOKEN"] = line.split("=")[1].strip()
        except:
            pass

    asyncio.run(check_issue())

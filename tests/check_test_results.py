import asyncio
import os
import sys

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from src.services.github_service import get_issue_details, search_issues_generic


async def main():
    issues = await search_issues_generic("is:issue [TEST] sort:created-desc")
    for issue in issues[:5]:
        print(f"Issue #{issue['number']}: {issue['title']}")
        details = await get_issue_details(issue["number"])
        print(f"  Labels: {details['labels']}")
        print(f"  State: {issue['state']}")
        print("-" * 20)


if __name__ == "__main__":
    asyncio.run(main())

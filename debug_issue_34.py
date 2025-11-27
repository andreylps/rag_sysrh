import asyncio
import os
import sys

from dotenv import load_dotenv

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from src.services.github_service import get_issue_details

load_dotenv()


async def debug_issue_34():
    print("Listando comentários da Issue #34 via get_issue_details...")
    details = await get_issue_details(34)
    comments = details.get("comments", [])

    print(f"Total de comentários: {len(comments)}")
    if comments:
        last_comment = comments[-1]
        print("--- ÚLTIMO COMENTÁRIO ---")
        print(last_comment["body"])
        print("-" * 20)
        if "## 🤖 RCM Revisada pela IA (Pós-Feedback)" in last_comment["body"]:
            print("MATCH FOUND!")
        else:
            print("NO MATCH")


if __name__ == "__main__":
    asyncio.run(debug_issue_34())

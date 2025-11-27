from typing import List, Optional

from langchain.tools import tool
from pydantic import BaseModel, Field

from src.services.github_service import post_comment, update_issue_labels


class GitHubApplyLabelsInput(BaseModel):
    issue_number: int = Field(description="The number of the GitHub issue to update.")
    labels_to_add: Optional[List[str]] = Field(
        default=None,
        description="List of labels to add to the issue (e.g., ['tipo:evolutiva', 'status:aguardando-validacao-rcm']).",
    )
    labels_to_remove: Optional[List[str]] = Field(
        default=None,
        description="List of labels to remove from the issue (e.g., ['status:nova']).",
    )


@tool("github_apply_labels", args_schema=GitHubApplyLabelsInput)
async def github_apply_labels(
    issue_number: int,
    labels_to_add: Optional[List[str]] = None,
    labels_to_remove: Optional[List[str]] = None,
) -> str:
    """
    Applies or removes labels from a GitHub issue.
    Use this tool to classify and route issues in the workflow.
    Common labels: 'tipo:evolutiva', 'tipo:correcao', 'status:aguardando-validacao-rcm', 'status:em-progresso'.
    """
    try:
        await update_issue_labels(
            issue_number=issue_number,
            add_labels=labels_to_add,
            remove_labels=labels_to_remove,
        )
        return f"Successfully updated labels for issue #{issue_number}."
    except Exception as e:
        return f"Error updating labels for issue #{issue_number}: {str(e)}"


class GitHubPostCommentInput(BaseModel):
    issue_number: int = Field(
        description="The number of the GitHub issue to comment on."
    )
    comment_body: str = Field(
        description="The markdown content of the comment to post."
    )


@tool("github_post_comment", args_schema=GitHubPostCommentInput)
async def github_post_comment(issue_number: int, comment_body: str) -> str:
    """
    Posts a comment on a GitHub issue.
    Use this tool to communicate with the user, post RCM drafts (Memória de Cálculo),
    or inform about the next steps in the workflow.
    """
    try:
        await post_comment(issue_number=issue_number, body=comment_body)
        return f"Successfully posted comment on issue #{issue_number}."
    except Exception as e:
        return f"Error posting comment on issue #{issue_number}: {str(e)}"


GITHUB_TOOLS = [github_apply_labels, github_post_comment]

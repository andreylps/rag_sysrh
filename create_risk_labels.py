import os

from dotenv import load_dotenv
from github import Github

load_dotenv()


def create_labels():
    token = os.getenv("GITHUB_TOKEN")
    repo_name = os.getenv("GITHUB_REPO_NAME")

    if not token or not repo_name:
        print("Error: GITHUB_TOKEN or GITHUB_REPO_NAME not set.")
        return

    if repo_name.endswith(".git"):
        repo_name = repo_name[:-4]

    g = Github(token)
    repo = g.get_repo(repo_name)

    labels_to_create = [
        {
            "name": "risco:sla-iminente",
            "color": "ff9f1c",
            "description": "Risco de estouro de SLA (>80%)",
        },
        {
            "name": "risco:sla-estourado",
            "color": "d00000",
            "description": "SLA estourado (>100%)",
        },
        {
            "name": "bloqueado:loop-qa",
            "color": "5a189a",
            "description": "Bloqueado por reprovações sucessivas no QA",
        },
        {
            "name": "sprint:atual",
            "color": "2ec4b6",
            "description": "Item planejado para a Sprint atual",
        },
    ]

    print(f"Checking labels for {repo_name}...")

    existing_labels = {l.name: l for l in repo.get_labels()}

    for label_data in labels_to_create:
        name = label_data["name"]
        if name in existing_labels:
            print(f"Label '{name}' already exists. Updating color...")
            existing_labels[name].edit(
                name=name,
                color=label_data["color"],
                description=label_data["description"],
            )
        else:
            print(f"Creating label '{name}'...")
            repo.create_label(
                name=name,
                color=label_data["color"],
                description=label_data["description"],
            )

    print("Labels configured successfully.")


if __name__ == "__main__":
    create_labels()

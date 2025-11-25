import os
import sys
import time

import requests

# Add src to path for github service check
sys.path.append(os.path.join(os.path.dirname(__file__), "src"))

# Import service to verify github state directly
from services.github_service import get_github_client, get_repo_name


def test_orchestration():
    url = "http://localhost:8000/api/v1/solicitacoes/"
    payload = {
        "titulo": "Teste de Orquestração Completa (IA)",
        "descricao": "Estou tentando gerar o arquivo de remessa para o banco, mas o sistema retorna erro de layout inválido (CNAB 240).",
    }

    print(f"Enviando solicitação para {url}...")
    try:
        response = requests.post(url, json=payload)
    except requests.exceptions.ConnectionError:
        print(
            "Erro: Não foi possível conectar ao servidor. Verifique se o uvicorn está rodando."
        )
        return

    if response.status_code != 200:
        print(f"Erro na requisição: {response.status_code} - {response.text}")
        return

    data = response.json()
    print("Resposta recebida:")
    print(data)

    issue_id = data.get("issue_id")
    if not issue_id:
        print("Issue ID não retornado!")
        return

    print(f"Issue #{issue_id} criada. Aguardando processamento em background (45s)...")
    # Aumentei o tempo pois a IA pode demorar
    time.sleep(45)

    # Verificar comentários
    print("Verificando comentários no GitHub...")
    try:
        g = get_github_client()
        repo = g.get_repo(get_repo_name())
        issue = repo.get_issue(issue_id)

        comments = list(issue.get_comments())
        print(f"Total de comentários: {len(comments)}")

        found_analysis = False
        for comment in comments:
            if "Análise Automática" in comment.body or "Análise" in comment.body:
                print("--- Comentário da IA Encontrado! ---")
                print(comment.body[:300] + "...")
                found_analysis = True
                break

        if found_analysis:
            print("SUCESSO: Orquestração completa validada.")
        else:
            print("FALHA: Comentário da IA não encontrado após espera.")

    except Exception as e:
        print(f"Erro ao verificar GitHub: {e}")


if __name__ == "__main__":
    test_orchestration()

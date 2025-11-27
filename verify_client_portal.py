import asyncio

from src.services.github_service import create_issue, post_comment, update_issue_labels


async def setup_test_case():
    print("Creating test issue for Client Portal verification...")

    # 1. Create Issue
    title = "[TESTE] Validação Portal Cliente"
    body = "Teste de verificação do novo portal do cliente com Dashboard e Histórico."
    issue_number = await create_issue(title, body)
    print(f"Issue created: #{issue_number}")

    # 2. Simulate Analyst Approval (Validation)
    print("Simulating Analyst Approval...")
    rcm_text = """
## ✅ RCM Validada pelo Analista

A seguinte Memória de Cálculo (RCM) foi revisada e aprovada para envio ao cliente:

---
# RCM - Relatório de Controle de Mudança

## Resumo
Implementação de melhorias no portal.

## Métricas
- **Pontos de Função:** 12.5
- **Prazo Estimado:** 5 dias úteis
- **Complexidade:** Média

## Solução Técnica
Implementação de frontend React e backend FastAPI.
---

**Próximo Passo:** Aguardando aprovação formal do cliente.
"""
    await post_comment(issue_number, rcm_text)

    # 3. Update Labels
    await update_issue_labels(
        issue_number,
        add_labels=["status:aguardando-aprovacao-cliente"],
        remove_labels=["status:nova"],
    )

    print("\nSUCCESS! Test case ready.")
    print(
        f"Access the Client Portal at: http://localhost:5173/cliente/aprovacao/{issue_number}"
    )


if __name__ == "__main__":
    asyncio.run(setup_test_case())

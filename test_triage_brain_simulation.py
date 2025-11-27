import asyncio
from unittest.mock import patch

from src.agents.triage_agent import run_triage_agent


# Mock das funções de serviço do GitHub para evitar chamadas reais
@patch("src.agents.github_tools.update_issue_labels")
@patch("src.agents.github_tools.post_comment")
async def run_simulation(mock_post_comment, mock_update_labels):
    print("=== Iniciando Simulação do Cérebro de Triagem ===")

    # Configura os mocks para serem assíncronos (retornarem Futures)
    mock_post_comment.return_value = asyncio.Future()
    mock_post_comment.return_value.set_result(None)
    mock_update_labels.return_value = asyncio.Future()
    mock_update_labels.return_value.set_result(None)

    # CASO 1: EVOLUTIVA
    print("\n--- Caso 1: Evolutiva (Novo Módulo) ---")
    title_evolutiva = "Novo módulo de Dependentes"
    body_evolutiva = "Precisamos de um novo módulo para cadastro de dependentes dos servidores, com upload de documentos."

    await run_triage_agent(101, title_evolutiva, body_evolutiva)

    # Verificações
    print("Verificando chamadas para Evolutiva:")

    # Verifica Labels
    if mock_update_labels.called:
        args, kwargs = mock_update_labels.call_args
        # O argumento pode vir posicional ou nomeado dependendo de como a tool chama
        labels_added = kwargs.get("add_labels") or (args[1] if len(args) > 1 else None)
        print(f"Labels Aplicadas: {labels_added}")
        if labels_added and "tipo:evolutiva" in labels_added:
            print("✅ Decisão Correta: Label 'tipo:evolutiva' aplicada.")
        else:
            print("⚠️ Aviso: Label 'tipo:evolutiva' não encontrada.")
    else:
        print("❌ Falha: Nenhuma label aplicada.")

    # Verifica Comentário (RCM)
    if mock_post_comment.called:
        args, kwargs = mock_post_comment.call_args
        body = kwargs.get("body") or (args[1] if len(args) > 1 else None)
        print(f"Comentário Postado (Trecho): {body[:50]}...")
        if "Rascunho Preliminar de RCM" in body:
            print("✅ Decisão Correta: Rascunho de RCM gerado.")
        else:
            print("⚠️ Aviso: Rascunho de RCM não detectado no comentário.")
    else:
        print("❌ Falha: Nenhum comentário postado.")

    # Reset mocks
    mock_update_labels.reset_mock()
    mock_post_comment.reset_mock()

    # CASO 2: CORREÇÃO
    print("\n--- Caso 2: Correção (Bug Crítico) ---")
    title_fix = "Erro 500 ao salvar férias"
    body_fix = (
        "Erro 500 ao tentar salvar férias quando a data fim é menor que a data início."
    )

    await run_triage_agent(102, title_fix, body_fix)

    # Verificações
    print("Verificando chamadas para Correção:")

    # Verifica Labels
    if mock_update_labels.called:
        args, kwargs = mock_update_labels.call_args
        labels_added = kwargs.get("add_labels") or (args[1] if len(args) > 1 else None)
        print(f"Labels Aplicadas: {labels_added}")
        if labels_added and "tipo:correcao" in labels_added:
            print("✅ Decisão Correta: Label 'tipo:correcao' aplicada.")
        else:
            print("⚠️ Aviso: Label 'tipo:correcao' não encontrada.")
    else:
        print("❌ Falha: Nenhuma label aplicada.")


if __name__ == "__main__":
    asyncio.run(run_simulation())

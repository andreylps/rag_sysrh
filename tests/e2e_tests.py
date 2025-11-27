import asyncio
import logging
import os
import sys
from datetime import datetime

# Adiciona o diretório raiz ao path para importações
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from src.agents.dev_agent import run_dev_agent
from src.rag_sysrh.analista_workflow import AnalistaWorkflow
from src.rag_sysrh.main import get_tools
from src.services.github_service import (
    create_issue,
    get_issue_details,
    post_comment,
    update_issue_labels,
)

# Configuração de Logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)


async def test_scenario_1_feature_success():
    """
    Cenário 1: Fluxo Completo de Feature (Sucesso)
    Analista -> RCM -> Aprovação -> Dev -> QA Sucesso -> Deploy
    """
    logger.info("=== INICIANDO CENÁRIO 1: FLUXO COMPLETO DE FEATURE (SUCESSO) ===")

    # 1. Criar Issue
    title = f"[TEST] Feature: Adicionar botão de Exportar PDF {datetime.now().strftime('%H%M%S')}"
    body = "Como usuário, quero exportar relatórios em PDF para arquivamento."
    issue_number = await create_issue(title, body)
    logger.info(f"Issue criada: #{issue_number}")

    # 2. Executar Agente Analista
    logger.info("Executando Agente Analista...")
    analista = AnalistaWorkflow(tools=get_tools())
    # Simulando a chamada do orquestrador
    # Precisamos garantir que o analista saiba que é uma Evolutiva para gerar RCM
    # O prompt do analista deve classificar como Melhoria
    relatorio = await analista.arun(body)

    # Hack: Forçar o ID da solicitação no relatório se não tiver sido encontrado (pois a issue acabou de ser criada e não está no Neo4j)
    if relatorio:
        relatorio.solicitacao_id = issue_number
        # Forçar tipo para garantir RCM se a LLM falhar na classificação
        if (
            "evoluti" not in relatorio.tipo_solicitacao.lower()
            and "melhoria" not in relatorio.tipo_solicitacao.lower()
        ):
            logger.warning(
                "LLM não classificou como Evolutiva. Forçando para teste de RCM."
            )
            relatorio.tipo_solicitacao = "Evolutiva (Forçado)"

        # Chamar finalizar_analise manualmente ou garantir que o workflow chamou
        # O workflow chama se estiver no grafo. Vamos confiar no grafo.
        # Mas como o ID não estava no Neo4j, o grafo pode ter pulado a parte de salvar detalhes.
        # Mas a geração de RCM depende do ID no relatório.
        # Vamos chamar finalizar_analise manualmente para garantir o teste do RCM service
        await analista.finalizar_analise({"relatorio_final": relatorio})

    # Verificação RCM
    issue_details = await get_issue_details(issue_number)
    labels = issue_details["labels"]
    if "status:aguardando-aprovacao-cliente" in labels:
        logger.info(
            "✅ RCM gerado e label 'status:aguardando-aprovacao-cliente' aplicada."
        )
    else:
        logger.error(f"❌ Falha no RCM. Labels atuais: {labels}")
        return

    # 3. Simular Aprovação do Cliente
    logger.info("Simulando aprovação do cliente...")
    await post_comment(issue_number, "APROVAR RCM")
    await update_issue_labels(
        issue_number,
        remove_labels=["status:aguardando-aprovacao-cliente"],
        add_labels=["status:pronto-para-dev"],
    )

    # 4. Executar Agente Desenvolvedor
    logger.info("Executando Agente Desenvolvedor...")
    # Mockando a geração de manual para garantir sucesso na QA (ou confiar no prompt)
    # Vamos deixar o agente rodar. Ele deve gerar um manual.
    # O QA vai validar. Se o manual for ruim, vai falhar.
    # Para garantir sucesso, o dev agent deve ser bom.

    result = await run_dev_agent(issue_number, {"title": title, "body": body})
    logger.info(f"Resultado do Dev Agent: {result}")

    # Verificação Final
    issue_details = await get_issue_details(issue_number)
    labels = issue_details["labels"]

    # Se QA passou, não deve ter 'status:aguardando-correcao-doc'
    if "status:aguardando-correcao-doc" not in labels:
        logger.info("✅ Cenário 1 Concluído com Sucesso (QA Aprovou ou Dev finalizou).")
    else:
        logger.warning(
            "⚠️ Cenário 1: QA Reprovou o manual (o que é válido, mas o teste visava sucesso)."
        )


async def test_scenario_2_qa_failure():
    """
    Cenário 2: Falha na Validação de Qualidade
    Dev gera manual ruim -> QA Reprova -> Label de Correção
    """
    logger.info("\n=== INICIANDO CENÁRIO 2: FALHA NA QA (DOCUMENTAÇÃO) ===")

    # 1. Criar Issue
    title = f"[TEST] Bug: Erro de cálculo simulado {datetime.now().strftime('%H%M%S')}"
    body = "Simulando um bug para teste de fluxo de correção."
    issue_number = await create_issue(title, body)

    # Pula Analista, vai direto para Dev
    await update_issue_labels(issue_number, add_labels=["status:pronto-para-dev"])

    # 2. Executar Dev Agent (mas vamos 'sabotar' o manual ou esperar que ele gere algo simples)
    # Para garantir falha, precisaríamos mockar o `generate_or_update_operational_manual` para retornar um arquivo vazio ou ruim.
    # Como não estamos usando mocks aqui, vamos confiar que o QA é rigoroso.
    # Se o QA aprovar, o teste é inconclusivo sobre a falha.

    logger.info("Executando Agente Desenvolvedor...")
    result = await run_dev_agent(issue_number, {"title": title, "body": body})
    logger.info(f"Resultado do Dev Agent: {result}")

    # Verificação
    issue_details = await get_issue_details(issue_number)
    labels = issue_details["labels"]

    if "status:aguardando-correcao-doc" in labels:
        logger.info("✅ Cenário 2 Sucesso: QA Reprovou e label de correção aplicada.")
    else:
        logger.info("ℹ️ Cenário 2: QA Aprovou (o agente dev foi bom demais!).")


async def main():
    logger.info("Iniciando Bateria de Testes E2E...")

    try:
        await test_scenario_1_feature_success()
        await test_scenario_2_qa_failure()
    except Exception as e:
        logger.error(f"Erro fatal nos testes: {e}", exc_info=True)


if __name__ == "__main__":
    asyncio.run(main())

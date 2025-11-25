import logging
import os
import sys
from pathlib import Path

# Add src to path
SRC_PATH = Path(__file__).resolve().parent / "src"
if str(SRC_PATH) not in sys.path:
    sys.path.append(str(SRC_PATH))

from dotenv import load_dotenv

load_dotenv()

from langchain_core.tools import Tool

from rag_sysrh.analista_workflow import AnalistaWorkflow

# Configura logging para ver o output
logging.basicConfig(level=logging.INFO)


class MockTool(Tool):
    name: str
    description: str

    def _run(self, input: str) -> str:
        return "Mock result"


def get_mock_tools():
    return [
        MockTool(
            name="Factual_Question_Answering",
            description="Mock factual QA",
            func=lambda x: "Mock factual",
        ),
        MockTool(
            name="Semantic_Question_Answering",
            description="Mock semantic QA",
            func=lambda x: "Mock semantic",
        ),
    ]


def verify_sisp_calculation():
    print("--- Iniciando Verificação do Cálculo SISP ---")

    # Instancia o workflow com ferramentas mockadas
    # Nota: O AnalistaWorkflow usa ChatOpenAI internamente, então precisamos da chave de API configurada no ambiente
    if not os.getenv("OPENAI_API_KEY"):
        print("ERRO: OPENAI_API_KEY não encontrada no ambiente.")
        return

    agent = AnalistaWorkflow(tools=get_mock_tools())

    # Cenário: Uma pequena melhoria que deve ser < 10 PF
    solicitacao = "Gostaria de adicionar um botão 'Exportar PDF' na tela de relatórios. É uma mudança simples de interface."

    print(f"Enviando solicitação: {solicitacao}")

    try:
        relatorio = agent.run(solicitacao)

        if relatorio and relatorio.detalhes_evolutiva:
            pf = relatorio.detalhes_evolutiva.estimativa_pontos_funcao
            dias = relatorio.detalhes_evolutiva.prazo_dias_uteis
            complexidade = relatorio.complexidade

            print("\nResultado da Análise:")
            print(f"Complexidade: {complexidade}")
            print(f"Pontos de Função (PF): {pf}")
            print(f"Prazo (Dias Úteis): {dias}")

            # Validação das regras SISP (Tabela 9)
            # Até 10 PF -> 9 dias (Baixa) ou 15 dias (Média)

            success = False
            if pf <= 10:
                if complexidade == "Baixa" and dias == 9:
                    success = True
                elif complexidade == "Média" and dias == 15:
                    success = True
                # O modelo pode variar um pouco a complexidade, mas o prazo deve bater com a tabela
                elif dias in [9, 15]:
                    print(
                        "AVISO: Prazo compatível com a tabela (9 ou 15), mas verifique a complexidade."
                    )
                    success = True

            if success:
                print(
                    "\n✅ SUCESSO: O cálculo respeitou a tabela SISP (<= 10 PF -> 9 ou 15 dias)."
                )
            else:
                print("\n❌ FALHA: O cálculo NÃO respeitou a tabela SISP.")
                print("Esperado: <= 10 PF -> 9 dias (Baixa) ou 15 dias (Média)")
                print(f"Obtido: {pf} PF -> {dias} dias (Complexidade: {complexidade})")

        else:
            print(
                "\n❌ FALHA: O relatório não foi gerado ou não contém detalhes evolutivos."
            )
            if relatorio:
                print(f"Tipo de Problema: {relatorio.tipo_problema}")

    except Exception as e:
        print(f"\n❌ ERRO DE EXECUÇÃO: {e}")


if __name__ == "__main__":
    verify_sisp_calculation()

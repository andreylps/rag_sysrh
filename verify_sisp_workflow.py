import sys
from pathlib import Path

from dotenv import load_dotenv

# Adiciona o diretório 'src' ao sys.path
SRC_PATH = Path(__file__).resolve().parent / "src"
if str(SRC_PATH) not in sys.path:
    sys.path.append(str(SRC_PATH))

load_dotenv()

from langgraph.checkpoint.memory import MemorySaver

from rag_sysrh.engine.models import EstadoEngenharia
from rag_sysrh.engine.workflow import SISPWorkflow


def verify_workflow():
    print("--- Verificando Workflow SISP com Human-in-the-Loop ---")

    # Configura memória para suportar interrupção/retomada
    memory = MemorySaver()
    workflow_cls = SISPWorkflow()

    # Precisamos recompilar passando o checkpointer para funcionar o HIL
    # Nota: A classe SISPWorkflow.build_graph original não aceitava checkpointer no exemplo anterior,
    # vamos instanciar e compilar manualmente aqui para teste ou ajustar a classe.
    # Ajustando para usar a definição da classe mas injetando checkpointer.

    workflow_graph = workflow_cls.build_graph()
    # O build_graph do código anterior já retorna o app compilado, mas sem checkpointer ele não persiste estado para resume.
    # Vamos re-criar o grafo aqui rapidamente com checkpointer para o teste ser fiel.

    from langgraph.graph import END, StateGraph

    builder = StateGraph(EstadoEngenharia)
    builder.add_node("analise_ia", workflow_cls._node_analise_ia)
    builder.add_node("validacao_humana", workflow_cls._node_human_input_check)
    builder.add_node("motor_sisp", workflow_cls._node_calculo_sisp)
    builder.set_entry_point("analise_ia")
    builder.add_edge("analise_ia", "validacao_humana")
    builder.add_edge("validacao_humana", "motor_sisp")
    builder.add_edge("motor_sisp", END)

    app = builder.compile(checkpointer=memory, interrupt_before=["validacao_humana"])

    # 1. Execução Inicial (Deve parar antes de 'validacao_humana')
    print("\n1. Iniciando execução (Esperado: Pausa após IA)...")
    thread_config = {"configurable": {"thread_id": "teste_hil_1"}}

    inputs = {
        "solicitacao_original": "Criar uma nova tela de consulta de logs de auditoria, com filtros por data e usuário. Os dados já existem no banco.",
        "diagnostico_tecnico": "Necessário criar interface frontend (Vue.js) e endpoint backend (FastAPI) para consulta (SELECT) na tabela de logs.",
    }

    # Executa até a interrupção
    for event in app.stream(inputs, config=thread_config):
        print(f"Evento: {event}")

    print("\n--- Workflow Pausado (Verificando Estado) ---")
    state_snapshot = app.get_state(thread_config)
    print(f"Próximo passo: {state_snapshot.next}")
    print(
        f"Itens Identificados pela IA: {len(state_snapshot.values['itens_identificados'])}"
    )
    if state_snapshot.values["itens_identificados"]:
        print(
            f"Exemplo: {state_snapshot.values['itens_identificados'][0].nome} - {state_snapshot.values['itens_identificados'][0].tipo}"
        )

    # 2. Simulação de Input Humano (Deflator)
    print("\n2. Fornecendo Input Humano (Deflator = 1.0)...")
    # Atualizamos o estado com o input do usuário
    app.update_state(thread_config, {"deflator_tabela0": 1.0})

    # 3. Retomada (Resume)
    print("\n3. Retomando execução...")
    # Passamos None como input pois o estado já foi atualizado
    for event in app.stream(None, config=thread_config):
        print(f"Evento Pós-Resume: {event}")

    print("\n--- Execução Finalizada ---")
    final_state = app.get_state(thread_config)
    res = final_state.values.get("resultado_sisp")

    if res:
        print(f"PF Bruto: {res.pf_bruto_total}")
        print(f"PF Líquido: {res.pf_liquido_total}")
        print(f"Prazo: {res.prazo_estimado_dias} dias")
        print(f"Memória de Cálculo: {res.memoria_calculo_path}")
        print(f"RCM: {res.rcm_path}")

        if "ERRO" not in res.memoria_calculo_path and "ERRO" not in res.rcm_path:
            print("✅ Workflow HIL + Docs Verificado com Sucesso!")
        else:
            print("⚠️ Workflow finalizado, mas com erros na geração de documentos.")
    else:
        print("❌ Falha: Resultado não encontrado.")


if __name__ == "__main__":
    verify_workflow()

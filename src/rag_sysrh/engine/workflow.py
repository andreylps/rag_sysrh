import logging

from langgraph.graph import END, StateGraph

from rag_sysrh.agents.auditor_agent import AuditorAgent
from rag_sysrh.engine.document_generator import DocumentGenerator
from rag_sysrh.engine.models import EstadoEngenharia
from rag_sysrh.engine.sisp_calculator import SISPCalculator
from rag_sysrh.services.functional_identifier import FunctionalIdentifier
from rag_sysrh.services.risk_assessor import RiskAssessor

# Configuração de Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class SISPWorkflow:
    # ...
    def __init__(self):
        self.risk_assessor = RiskAssessor()
        self.functional_identifier = FunctionalIdentifier()
        self.calculator = SISPCalculator()
        self.doc_generator = DocumentGenerator()
        self.auditor = AuditorAgent()

    def _node_analise_ia(self, state: EstadoEngenharia) -> dict:
        """
        Nó 1: Análise de IA (Risco + Identificação Funcional)
        """
        logger.info("--- Executando Análise de IA ---")

        # 1. Avaliação de Risco
        risco = self.risk_assessor.avaliar_risco(
            state.solicitacao_original, state.diagnostico_tecnico
        )

        # 2. Identificação Funcional
        itens = self.functional_identifier.identificar_itens(
            state.solicitacao_original, state.diagnostico_tecnico
        )

        return {"avaliacao_risco": risco, "itens_identificados": itens}

    def _node_human_input_check(self, state: EstadoEngenharia) -> dict:
        """
        Nó 2: Checkpoint Humano (Pass-through)
        O grafo é interrompido ANTES deste nó. Quando retomado,
        o estado já deve conter o 'deflator_tabela0' injetado pelo usuário.
        """
        logger.info("--- Checkpoint Humano Verificado ---")
        # Aqui poderíamos validar se o deflator foi preenchido
        return {}

    def _node_calculo_sisp(self, state: EstadoEngenharia) -> dict:
        """
        Nó 3: Motor de Cálculo Determinístico
        """
        logger.info("--- Executando Motor de Cálculo SISP ---")

        resultado = self.calculator.calcular_pf(
            state.itens_identificados,
            state.deflator_tabela0
            or 1.0,  # Default para 1.0 se não informado (segurança)
        )

        return {"resultado_sisp": resultado}

    def _node_geracao_docs(self, state: EstadoEngenharia) -> dict:
        """
        Nó 4: Geração de Documentos
        """
        logger.info("--- Gerando Documentação Formal ---")

        # Atualiza caminhos no objeto de resultado
        res = state.resultado_sisp

        # Gera Excel
        path_excel = self.doc_generator.gerar_memoria_calculo(res)
        res.memoria_calculo_path = str(path_excel)

        # Gera Word (RCM)
        path_word = self.doc_generator.gerar_rcm(
            state.solicitacao_original,
            state.diagnostico_tecnico,
            res,
            state.avaliacao_risco,
        )
        res.rcm_path = str(path_word)

        return {"resultado_sisp": res}

    def _node_auditoria_qualidade(self, state: EstadoEngenharia) -> dict:
        """
        Nó 5: Auditoria de Qualidade (Quality Gate)
        """
        logger.info("--- Executando Auditoria de Qualidade ---")

        verdict = self.auditor.audit_delivery(
            state.resultado_sisp, state.diagnostico_tecnico
        )

        return {"audit_verdict": verdict}

    def build_graph(self):
        """
        Constrói e compila o grafo LangGraph.
        """
        workflow = StateGraph(EstadoEngenharia)

        # Adiciona Nós
        workflow.add_node("analise_ia", self._node_analise_ia)
        workflow.add_node("validacao_humana", self._node_human_input_check)
        workflow.add_node("motor_sisp", self._node_calculo_sisp)
        workflow.add_node("geracao_docs", self._node_geracao_docs)
        workflow.add_node("auditoria_qualidade", self._node_auditoria_qualidade)

        # Define Arestas
        workflow.set_entry_point("analise_ia")
        workflow.add_edge("analise_ia", "validacao_humana")
        workflow.add_edge("validacao_humana", "motor_sisp")
        workflow.add_edge("motor_sisp", "geracao_docs")
        workflow.add_edge("geracao_docs", "auditoria_qualidade")
        workflow.add_edge("auditoria_qualidade", END)

        # Compila com INTERRUPÇÃO antes da validação/cálculo
        return workflow.compile(interrupt_before=["validacao_humana"])

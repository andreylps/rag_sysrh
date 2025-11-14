import logging
from typing import TypedDict

from langchain_core.exceptions import OutputParserException
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.tools import Tool
from langchain_openai import ChatOpenAI
from langgraph.graph import END, StateGraph
from pydantic import BaseModel, Field

# Configura o logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


class DetalhesEvolutiva(BaseModel):
    """
    Modelo de dados para os detalhes específicos de uma solicitação evolutiva.
    """

    data_prevista_entrega: str = Field(
        description="Data estimada para a entrega da nova funcionalidade ou melhoria (formato DD/MM/AAAA)."  # noqa: E501
    )
    estimativa_pontos_funcao: int = Field(
        description="Estimativa do tamanho da funcionalidade em Pontos de Função (PF)."
    )
    prazo_dias_uteis: int = Field(
        description="Prazo total estimado em dias úteis para a entrega."
    )


class AnaliseRelatorio(BaseModel):
    """
    Modelo de dados para o relatório final de análise da solicitação.
    """

    tipo_problema: str = Field(
        description="Classificação do tipo de problema (ex: Dúvida, Erro, Melhoria)."
    )
    tipo_solicitacao: str = Field(
        description="Classifique a solicitação em uma das seguintes categorias: Evolutivo, Corretivo, Operacao, Transferencia de conhecimento, Correcao de dados, Migracao, Garantia."  # noqa: E501
    )
    resumo_problema: str = Field(
        description="Resumo conciso do problema ou necessidade do usuário."
    )
    diagnostico: str = Field(
        description="Análise da causa raiz, com base em manuais e histórico."
    )
    complexidade: str = Field(
        description="Complexidade do ajuste necessário (Baixa, Média, Alta, Ultra)."
    )
    solucao_sugerida: str = Field(
        description="Passos ou ações recomendadas para resolver a solicitação."
    )
    nivel_esforco: str = Field(
        description="Nível de esforço calculado (Baixo, Médio, Alto) com base na complexidade, pontos de função e prazo."  # noqa: E501
    )
    esforco_resolucao_dias: str = Field(
        description="Estimativa do esforço de resolução em dias úteis (ex: '0-2 dias', '3-7 dias', '8-15 dias', '15-30 dias')."  # noqa: E501
    )
    detalhes_evolutiva: DetalhesEvolutiva | None = Field(
        description="Detalhes específicos se a solicitação for classificada como 'Melhoria' ou 'Evolutiva'. Caso contrário, deve ser nulo."  # noqa: E501
    )


class WorkflowState(TypedDict):
    """
    Define o estado que será passado entre os nós do grafo LangGraph.
    Usar TypedDict é a abordagem recomendada para compatibilidade com type checkers.
    """

    solicitacao_original: str
    classificacao: str | None
    dados_historico: list[str] | None
    dados_manuais: list[str] | None
    dados_rcm_especifico: str | None
    diagnostico: str | None
    relatorio_final: AnaliseRelatorio | None


class AnalistaWorkflow:
    """
    Implementa o workflow de análise de solicitações usando LangGraph,
    alinhado com a Fase 2 do resumo estratégico.
    """

    def __init__(self, tools: list[Tool]) -> None:
        self.llm = ChatOpenAI(model="gpt-4-turbo", temperature=0)
        self.tools_by_name = {tool.name: tool for tool in tools}
        self.graph = self._build_graph()

    def _build_graph(self):  # noqa: ANN202
        workflow = StateGraph(WorkflowState)

        # Adiciona os nós (passos) do workflow
        workflow.add_node("classificar_solicitacao", self.classificar_solicitacao)
        workflow.add_node("identificar_e_buscar_rcm", self.identificar_e_buscar_rcm)
        workflow.add_node("buscar_no_historico", self.buscar_no_historico)
        workflow.add_node("consultar_manuais", self.consultar_manuais)
        workflow.add_node("gerar_diagnostico", self.gerar_diagnostico)
        workflow.add_node("gerar_relatorio_final", self.gerar_relatorio_final)

        # Define as arestas (fluxo)
        workflow.set_entry_point("classificar_solicitacao")
        workflow.add_edge("classificar_solicitacao", "identificar_e_buscar_rcm")
        workflow.add_edge("identificar_e_buscar_rcm", "buscar_no_historico")
        workflow.add_edge("buscar_no_historico", "consultar_manuais")
        workflow.add_edge("consultar_manuais", "gerar_diagnostico")
        workflow.add_edge("gerar_diagnostico", "gerar_relatorio_final")
        workflow.add_edge("gerar_relatorio_final", END)

        return workflow.compile()

    def classificar_solicitacao(self, state: WorkflowState):  # noqa: ANN201
        logging.info("Passo 1: Classificando a solicitação...")  # noqa: LOG015
        prompt = ChatPromptTemplate.from_template(
            "Classifique a seguinte solicitação de usuário em uma das categorias: 'Dúvida de Procedimento', 'Relato de Erro', 'Solicitação de Melhoria'.\n\nSolicitação: {solicitacao}"  # noqa: E501
        )
        chain = prompt | self.llm
        classificacao = chain.invoke(
            {"solicitacao": state["solicitacao_original"]}
        ).content
        return {"classificacao": classificacao}

    def identificar_e_buscar_rcm(self, state: WorkflowState):  # noqa: ANN201
        """Identifica se um RCM é citado e busca seus dados."""
        logging.info("Passo 2: Identificando RCM específico...")  # noqa: LOG015

        prompt = ChatPromptTemplate.from_template(
            "Analise o texto a seguir e extraia o número de um RCM, se houver. O número pode estar no formato 'RCM-1234' ou apenas '1234'. Se nenhum número de RCM for encontrado, retorne 'N/A'.\n\nTexto: {solicitacao}"  # noqa: E501
        )
        chain = prompt | self.llm | StrOutputParser()
        rcm_id_str = chain.invoke({"solicitacao": state["solicitacao_original"]})

        if rcm_id_str and rcm_id_str != "N/A":
            rcm_id = "".join(filter(str.isdigit, rcm_id_str))
            logging.info(f"RCM ID {rcm_id} encontrado. Buscando dados...")  # noqa: LOG015, G004
            factual_tool = self.tools_by_name["Factual_Question_Answering"]
            query = f"Qual o esforço em horas e o texto completo do RCM {rcm_id}?"
            dados_rcm = factual_tool.invoke({"input": query})
            return {"dados_rcm_especifico": dados_rcm}
        return {"dados_rcm_especifico": None}

    def buscar_no_historico(self, state: WorkflowState):  # noqa: ANN201
        logging.info("Passo 2: Buscando no histórico de solicitações...")  # noqa: LOG015
        query = (
            f"Liste solicitações ou RCMs similares a: '{state['solicitacao_original']}'"
        )
        factual_tool = self.tools_by_name["Factual_Question_Answering"]
        resultado_historico = factual_tool.invoke({"input": query})
        return {"dados_historico": [resultado_historico]}

    def consultar_manuais(self, state: WorkflowState):  # noqa: ANN201
        logging.info("Passo 3: Consultando manuais e regras de negócio...")  # noqa: LOG015
        query = (
            f"Explique o procedimento ou regra sobre: '{state['solicitacao_original']}'"
        )
        semantic_tool = self.tools_by_name["Semantic_Question_Answering"]
        resultado_manuais = semantic_tool.invoke({"input": query})
        return {"dados_manuais": [resultado_manuais]}

    def gerar_diagnostico(self, state: WorkflowState):  # noqa: ANN201
        logging.info("Passo 4: Gerando diagnóstico...")  # noqa: LOG015
        prompt = ChatPromptTemplate.from_template(
            """Você é um analista de sistemas sênior. Com base nas informações coletadas, gere um diagnóstico técnico detalhado para que a equipe de desenvolvimento possa atuar.

            Solicitação Original: {solicitacao}
            Classificação: {classificacao}
            Dados do Histórico (solicitações parecidas): {historico}
            Dados de RCM Específico (se aplicável): {rcm_especifico}
            Dados dos Manuais (regras e procedimentos): {manuais}

            **Instruções:**
            1.  Se a **Classificação** for 'Solicitação de Melhoria' (demanda evolutiva), o diagnóstico deve ser impecável e servir de base para a criação de uma RCM (Requisição de Mudança). Detalhe os seguintes pontos:
                - **Análise do Problema:** Descreva a necessidade de negócio e o valor que a nova funcionalidade agregará.
                - **Requisitos Técnicos para Solução:** Detalhe os componentes necessários (novas telas, campos, botões, alterações em APIs, etc.) e as regras de negócio que devem ser implementadas.
                - **Impacto:** Mencione outras partes do sistema que podem ser impactadas.

            2.  Se a **Classificação** for 'Relato de Erro' ou 'Dúvida de Procedimento', o diagnóstico deve focar em:
                - **Análise do Problema:** Descreva o comportamento inesperado ou a dúvida do usuário.
                - **Causa Raiz:** Identifique a possível causa do erro (ex: dados inconsistentes, falha em regra de negócio) ou aponte o procedimento correto com base nos manuais.

            **Diagnóstico Técnico Detalhado:**"""
        )
        chain = prompt | self.llm
        diagnostico_str = chain.invoke(
            {
                "solicitacao": state["solicitacao_original"],
                "classificacao": state["classificacao"],
                "historico": state["dados_historico"],
                "rcm_especifico": state["dados_rcm_especifico"]
                or "Nenhum RCM específico mencionado.",
                "manuais": state["dados_manuais"],
            }
        ).content
        return {"diagnostico": diagnostico_str}

    def gerar_relatorio_final(self, state: WorkflowState):  # noqa: ANN201
        logging.info("Passo 5: Gerando relatório final...")  # noqa: LOG015
        structured_llm = self.llm.with_structured_output(AnaliseRelatorio)
        prompt = ChatPromptTemplate.from_template(
            """Gere um relatório de análise estruturado com base em todo o contexto.
            Seu objetivo é preencher todos os campos do modelo `AnaliseRelatorio`.

            Solicitação Original: {solicitacao}
            Classificação: {classificacao}
            Dados de RCM Específico (se aplicável): {rcm_especifico}
            Diagnóstico Técnico: {diagnostico}

            Instruções para preenchimento:
            1.  **tipo_problema**: Use a classificação já fornecida (Dúvida, Erro, Melhoria).
            2.  **tipo_solicitacao**: Com base no contexto do problema, classifique a solicitação em uma das seguintes categorias: 'Evolutivo', 'Corretivo', 'Operacao', 'Transferencia de conhecimento', 'Correcao de dados', 'Migracao', 'Garantia'.
            3.  **resumo_problema**: Crie um resumo conciso do problema.
            4.  **diagnostico**: Use o diagnóstico técnico fornecido.
            5.  **complexidade**: Com base no diagnóstico e, PRINCIPALMENTE, nos dados do RCM específico (se houver), classifique a complexidade como 'Baixa', 'Média', 'Alta' ou 'Ultra'. Se um RCM similar teve esforço alto, a complexidade deve ser compatível.
            6.  **solucao_sugerida**: Descreva os passos ou a solução técnica recomendada.
            7.  **esforco_resolucao_dias**: Com base na complexidade definida, estime o esforço de resolução em dias úteis seguindo estas regras: 'Baixa' -> '0-2 dias', 'Média' -> '3-7 dias', 'Alta' -> '8-15 dias', 'Ultra' -> '15-30 dias'.
            8.  **detalhes_evolutiva**: Se o `tipo_problema` for 'Melhoria' ou 'Evolutivo', preencha os sub-campos:
                - **data_prevista_entrega**: Estime uma data de entrega realista.
                - **estimativa_pontos_funcao**: Forneça uma estimativa em Pontos de Função (ex: 8, 16, 32). Baseie-se no esforço do RCM específico, se disponível.
                - **prazo_dias_uteis**: Calcule o número de dias úteis até a data de entrega.
                - Se não for uma melhoria, retorne `null` para este campo.
            9.  **nivel_esforco**: Calcule o nível de esforço (Baixo, Médio, Alto) combinando a `complexidade` e a `estimativa_pontos_funcao`."""  # noqa: E501
        )
        chain = prompt | structured_llm
        try:
            relatorio = chain.invoke(
                {
                    "solicitacao": state["solicitacao_original"],
                    "classificacao": state["classificacao"],
                    "rcm_especifico": state["dados_rcm_especifico"]
                    or "Nenhum RCM específico mencionado.",
                    "diagnostico": state["diagnostico"],
                }
            )
            return {"relatorio_final": relatorio}  # noqa: TRY300
        except OutputParserException as e:
            logging.exception("Falha ao parsear a saída do LLM: %s", e)  # noqa: LOG015, TRY401
            # Retorna um estado de erro ou um relatório parcial
            return {
                "relatorio_final": AnaliseRelatorio(
                    tipo_problema="Erro de Análise",
                    resumo_problema=f"Ocorreu um erro ao gerar o relatório: {e}",
                    diagnostico="",
                    complexidade="N/A",
                    solucao_sugerida="",
                    nivel_esforco="N/A",
                    esforco_resolucao_dias="N/A",
                    tipo_solicitacao="N/A",
                    detalhes_evolutiva=None,
                )
            }

    def run(self, solicitacao: str) -> AnaliseRelatorio:
        """Executa o workflow completo para uma dada solicitação."""
        # Inicializa o estado com todas as chaves para satisfazer o type checker.
        initial_state: WorkflowState = {
            "solicitacao_original": solicitacao,
            "classificacao": None,
            "dados_historico": None,
            "dados_rcm_especifico": None,
            "dados_manuais": None,
            "diagnostico": None,
            "relatorio_final": None,
        }
        final_state = self.graph.invoke(initial_state)
        return final_state["relatorio_final"]


if __name__ == "__main__":
    # Exemplo de uso alinhado à Fase 2
    from rag_sysrh.main import get_tools

    analista_agent = AnalistaWorkflow(tools=get_tools())

    texto_solicitacao = "Estou tentando registrar uma proposta de consignação para o cliente UDESC, mas o sistema apresenta o erro 'RN005 - Limite excedido'. O que devo fazer?"  # noqa: E501

    relatorio = analista_agent.run(texto_solicitacao)

    print("\n--- Relatório de Análise da Solicitação ---")
    # Corrigido para usar os nomes de atributo corretos do modelo AnaliseRelatorio
    print(f"Classificação: {relatorio.tipo_problema}")
    print(f"Resumo: {relatorio.resumo_problema}")
    print(f"Diagnóstico: {relatorio.diagnostico}")
    print(f"Solução Sugerida: {relatorio.solucao_sugerida}")
    print(f"Nível de Esforço: {relatorio.nivel_esforco}")

from typing import List

from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI
from pydantic import BaseModel, Field

from rag_sysrh.core.knowledge_base import get_contexto_organizacional_completo
from rag_sysrh.engine.models import ItemFuncional


class ListaItensFuncionais(BaseModel):
    itens: List[ItemFuncional] = Field(
        ..., description="Lista de itens funcionais identificados"
    )


class FunctionalIdentifier:
    """
    Serviço responsável por identificar funções de dados e transação (ALI, AIE, EE, SE, CE)
    conforme o manual SISP, a partir da descrição da demanda.
    """

    def __init__(self, model_name: str = "gpt-4o"):
        # Usa um modelo mais capaz (GPT-4o) pois a identificação de PF exige raciocínio complexo
        self.llm = ChatOpenAI(model=model_name, temperature=0)

    def identificar_itens(
        self, solicitacao: str, diagnostico: str
    ) -> List[ItemFuncional]:
        """
        Identifica itens funcionais (ALI, AIE, EE, SE, CE) usando LLM.
        """
        contexto_org = get_contexto_organizacional_completo()

        prompt = ChatPromptTemplate.from_messages(
            [
                (
                    "system",
                    f"""Você é um Analista de Métricas de Software SISP 2.3.
            
            {contexto_org}
            
            Identifique as funções de dados (ALI, AIE) e transações (EE, SE, CE) impactadas.
            
            Regras:
            1. ALI: Arquivos lógicos internos mantidos pelo sistema.
            2. AIE: Arquivos lógicos referenciados (apenas leitura) de outros sistemas.
            3. EE: Entrada de dados que atualiza ALIs (ex: Cadastros).
            4. SE: Saída de dados com processamento lógico (ex: Relatórios calculados).
            5. CE: Consulta simples sem processamento complexo.
            6. NAO_MENSURAVEL: Itens técnicos (ex: refatoração, script banco) que não contam PF.
            
            Para itens NAO_MENSURAVEL, defina DER=0 e RLR=0.
            
            Use o contexto organizacional para entender quais dados pertencem a quais times (ex: Dados Funcionais vs Folha).
            """,
                ),
                ("user", "Solicitação: {solicitacao}\nDiagnóstico: {diagnostico}"),
            ]
        )

        chain = prompt | self.llm.with_structured_output(ListaItensFuncionais)

        resultado = chain.invoke(
            {"solicitacao": solicitacao, "diagnostico": diagnostico}
        )

        return resultado.itens

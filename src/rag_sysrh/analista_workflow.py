import logging
import os
from typing import TypedDict

from langchain_core.exceptions import (  # type: ignore
    OutputParserException,  # pyright: ignore[reportMissingImports]
)
from langchain_core.output_parsers import (  # type: ignore
    StrOutputParser,  # pyright: ignore[reportMissingImports]
)
from langchain_core.prompts import (  # type: ignore
    ChatPromptTemplate,  # pyright: ignore[reportMissingImports]
)
from langchain_core.tools import Tool  # type: ignore
from langchain_neo4j import Neo4jGraph  # type: ignore
from langchain_openai import ChatOpenAI  # type: ignore
from langgraph.graph import END, StateGraph  # type: ignore
from pydantic import BaseModel, Field  # type: ignore

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


class RelatorioAnalise(BaseModel):
    """
    Modelo de dados para o relatório final de análise da solicitação.
    """

    solicitacao_id: int | None = Field(
        default=None,
        description="O ID numérico da solicitação original no banco de dados.",
    )
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
    dados_historico: str | list | dict | None
    dados_manuais: str | list | dict | None
    dados_rcm_especifico: str | None
    diagnostico: str | None
    dados_metricas: str | None
    relatorio_final: RelatorioAnalise | None
    solicitacao_id: int | None


class AnalistaWorkflow:
    """
    Implementa o workflow de análise de solicitações usando LangGraph,
    alinhado com a Fase 2 do resumo estratégico.
    """

    def __init__(self, tools: list[Tool]) -> None:
        self.llm = ChatOpenAI(model="gpt-4-turbo", temperature=0)
        self.tools_by_name = {tool.name: tool for tool in tools}
        self.db_graph = Neo4jGraph(
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
        )
        self.graph = self._build_graph()

    def _buscar_solicitacao_por_texto(self, texto_solicitacao: str) -> int:
        """Busca o ID de uma solicitação no grafo usando seu texto/título."""
        logging.info("Buscando ID da solicitação correspondente no grafo...")
        # Esta query busca por similaridade no título ou na descrição completa
        query = """
        MATCH (s:Solicitacao)
        WHERE s.title CONTAINS $texto OR s.texto_completo CONTAINS $texto
        RETURN s.id AS id
        LIMIT 1
        """
        resultado = self.db_graph.query(query, params={"texto": texto_solicitacao})
        if resultado:
            solicitacao_id = resultado[0]["id"]
            logging.info(f"Solicitação encontrada com ID: {solicitacao_id}")
            return solicitacao_id
        return -1  # Retorna um ID inválido se não encontrar

    def classificar_solicitacao(self, state: WorkflowState):  # noqa: ANN201
        logging.info("Passo 1: Classificando a solicitação...")  # noqa: LOG015
        prompt = ChatPromptTemplate.from_template(
            """Classifique a solicitação do usuário em uma das categorias abaixo:

            <categorias>
            - 'Dúvida de Procedimento': O usuário não sabe como fazer algo ou pergunta sobre regras.
            - 'Relato de Erro': O sistema apresentou falha, mensagem de erro ou comportamento inesperado.
            - 'Solicitação de Melhoria': O usuário pede uma nova funcionalidade, alteração de campo ou relatório novo.
            </categorias>

            Solicitação: {solicitacao}
            Classificação:"""
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
        return {"dados_historico": resultado_historico}

    def _determine_cache_key(self, text: str) -> str:
        """Determina a chave de cache do CAG com base no conteúdo da solicitação."""
        text_lower = text.lower()

        # Regras simples de roteamento de contexto
        if any(
            term in text_lower
            for term in ["faturamento", "custo", "financeiro", "valor", "pagamento"]
        ):
            return "faturamento_rules"

        # Default para procedimentos gerais do SISP
        return "sisp_completo"

    async def consultar_manuais(self, state: WorkflowState):  # noqa: ANN201
        logging.info("Passo 3: Consultando manuais e regras de negócio...")  # noqa: LOG015

        # --- CAG: Context Augmented Generation ---
        # Verifica se existe um contexto "quente" no cache baseado no domínio da pergunta
        from src.rag_sysrh.services.cag_service import cag_service

        # --- INJEÇÃO NUCLEAR (FIX 07/12) ---
        # Recupera memória SISP e injeta direto no Prompt do Usuário
        try:
            print(
                f"DEBUG: Analisando solicitacao: {state.get('solicitacao_original', 'N/A')}"
            )
            # Ensure get_redis is available if top-level import fails or for clarity as in snippet
            from src.rag_sysrh.infra.cache import get_redis

            rc = await get_redis()
            mem = await rc.get("sisp_completo")

            if mem:
                print(
                    f"DEBUG: [NUCLEAR] Memória Redis encontrada ({len(mem)} chars). Injetando..."
                )

                # Formata o contexto para ser impossível de ignorar
                contexto_extra = (
                    f"\n\n[CONTEXTO PRIORITÁRIO RECUPERADO DO SISTEMA]: {mem}"
                )

                # 1. Injeta na Pergunta Original (Garante que a LLM leia)
                if "solicitacao_original" in state:
                    state["solicitacao_original"] += contexto_extra

                # 2. Injeta na lista de documentos (Backup padrão)
                if "docs" not in state:
                    state["docs"] = []
                if isinstance(state["docs"], list):
                    state["docs"].append(contexto_extra)

                print(
                    "DEBUG: [NUCLEAR] Contexto injetado na solicitacao_original com sucesso!"
                )
            else:
                print("DEBUG: [CAG MISS] Cache sisp_completo vazio.")

        except Exception as e_nuc:
            print(f"DEBUG: [NUCLEAR ERROR] Falha na injeção de memória: {e_nuc}")
        # -----------------------------------

        print(
            f"DEBUG: Iniciando busca para a pergunta: {state['solicitacao_original']}"
        )
        cache_key = self._determine_cache_key(state["solicitacao_original"])
        logging.info(f"🔑 Chave CAG determinada: '{cache_key}'")

        cag_context = await cag_service.get_context(cache_key)

        # Tenta recuperar o contexto global SISP (se não foi o retornado inicialmente)
        if not cag_context:
            print(
                f"DEBUG: Chave '{cache_key}' vazia. Tentando fallback para 'sisp_completo'..."
            )
            contexto_cache = await cag_service.get_context("sisp_completo")
            if contexto_cache:
                print("DEBUG: [CAG HIT] Contexto sisp_completo encontrado no Redis!")
                cag_context = contexto_cache
                cache_key = "sisp_completo"
            else:
                print("DEBUG: [CAG MISS] Chave sisp_completo não encontrada ou vazia.")

        if cag_context:
            logging.info(
                f"⚡ [CAG Cached Hit] Contexto '{cache_key}' recuperado do Redis."
            )
            # Retorna o contexto do cache, prefixado para indicar a origem
            return {
                "dados_manuais": f"[CAG CACHE ATIVO ({cache_key})] Contexto Recuperado:\n{cag_context}"
            }

        # Fallback: Busca Vetorial Padrão
        logging.info(f"Cache Miss ({cache_key}). Executando busca vetorial no Neo4j...")
        query = (
            f"Explique o procedimento ou regra sobre: '{state['solicitacao_original']}'"
        )
        semantic_tool = self.tools_by_name["Semantic_Question_Answering"]
        # Invocação síncrona da tool (compatível se thread executora permitir I/O)
        resultado_manuais = semantic_tool.invoke({"input": query})
        return {"dados_manuais": resultado_manuais}

    @staticmethod
    def _get_regras_sisp() -> str:
        """Retorna as regras de contagem SISP 2.3."""
        return """
        REGRAS DE CONTAGEM SISP 2.3 (Roteiro de Métricas):

        1. TABELA DE VALORES DE PONTOS DE FUNÇÃO (PF):
        | Tipo de Função | Complexidade Baixa | Complexidade Média | Complexidade Alta |
        | :--- | :---: | :---: | :---: |
        | ALI (Arquivo Lógico Interno) | 7 PF | 10 PF | 15 PF |
        | AIE (Arquivo de Interface Externa) | 5 PF | 7 PF | 10 PF |
        | EE (Entrada Externa) | 3 PF | 4 PF | 6 PF |
        | SE (Saída Externa) | 4 PF | 5 PF | 7 PF |
        | CE (Consulta Externa) | 3 PF | 4 PF | 6 PF |

        2. TABELA DE COMPLEXIDADE - FUNÇÕES DE DADOS (ALI/AIE):
        | TR (Tipos de Registro) | 1 a 19 TD (Tipos de Dado) | 20 a 50 TD | > 50 TD |
        | :--- | :---: | :---: | :---: |
        | 1 TR | Baixa | Baixa | Média |
        | 2 a 5 TR | Baixa | Média | Alta |
        | > 5 TR | Média | Alta | Alta |

        3. TABELA DE COMPLEXIDADE - FUNÇÕES DE TRANSAÇÃO (EE/SE/CE):
        | AR (Arquivos Referenciados) | 1 a 4 TD (Tipos de Dado) | 5 a 15 TD | > 15 TD |
        | :--- | :---: | :---: | :---: |
        | 0 a 1 AR | Baixa | Baixa | Média |
        | 2 a 3 AR | Baixa | Média | Alta |
        | > 3 AR | Média | Alta | Alta |

        4. TABELA DE PRAZOS (SISP 2.3 - Tabela 9):
        | Tamanho (PF) | Prazo Máx (Dias) - Baixa | Prazo Máx (Dias) - Média |
        | :--- | :---: | :---: |
        | Até 10 PF | 9 | 15 |
        | 11-20 PF | 18 | 30 |
        | 21-30 PF | 27 | 45 |
        | 31-40 PF | 36 | 60 |
        | 41-50 PF | 45 | 75 |
        """

    def consultar_metricas(self, state: WorkflowState):  # noqa: ANN201
        logging.info("Passo 3.5: Consultando guia de métricas SISP...")
        return {"dados_metricas": self._get_regras_sisp()}

    async def processar_rejeicao(self, rcm_text: str, client_feedback: str) -> str:
        """
        Processa a rejeição do cliente, revisando o RCM com base no feedback.
        """
        logging.info("Iniciando revisão automática de RCM baseada em feedback...")

        regras_sisp = self._get_regras_sisp()

        prompt = ChatPromptTemplate.from_template(
            """Você é um Analista de Sistemas Sênior responsável por ajustar uma Proposta Técnica (RCM).
            
            O cliente REJEITOU a proposta atual com o seguinte feedback:
            "{feedback}"

            <rcm_atual>
            {rcm_text}
            </rcm_atual>
            
            <regras_sisp>
            {regras_sisp}
            </regras_sisp>

            <instrucoes>
            1. Analise o feedback do cliente e identifique o que precisa ser alterado no RCM.
            2. Reescreva o RCM mantendo a estrutura original, mas aplicando as correções solicitadas.
            3. Adicione uma seção no início do documento chamada "## 📝 Notas de Revisão (IA)" explicando brevemente o que foi alterado para atender ao cliente.
            4. Se o feedback for vago, faça o melhor esforço para interpretar ou adicione notas perguntando ao analista humano.
            5. Mantenha o tom profissional e técnico.
            6. CRÍTICO: Você DEVE manter as seções de métricas originais no final ou no corpo do texto.
               - Se elas existirem no texto original, MANTENHA-AS EXATAMENTE COMO ESTÃO.
               - Se elas ESTIVEREM FALTANDO (ex: Prazo Estimado sumiu), você DEVE RECALCULAR e adicionar com base nas <regras_sisp> e na estimativa de PFs.
               
               Formato Obrigatório das Métricas:
               "**Estimativa de Pontos de Função (PF):** X PF"
               "**Prazo Estimado:** Y dias"
               
               Não remova essas informações, pois elas alimentam o dashboard do cliente.
            </instrucoes>

            RCM Revisado:"""
        )

        chain = prompt | self.llm | StrOutputParser()

        try:
            novo_rcm = await chain.ainvoke(
                {
                    "feedback": client_feedback,
                    "rcm_text": rcm_text,
                    "regras_sisp": regras_sisp,
                }
            )
            logging.info("RCM revisado com sucesso pela IA.")
            return novo_rcm
        except Exception as e:
            logging.exception(f"Erro ao revisar RCM: {e}")
            # Em caso de erro, retorna o original com uma nota
            return f"## ⚠️ Erro na Revisão Automática\n\nNão foi possível processar o feedback automaticamente. Erro: {e}\n\n---\n\n{rcm_text}"

    def gerar_diagnostico(self, state: WorkflowState):  # noqa: ANN201
        logging.info("Passo 4: Gerando diagnóstico...")  # noqa: LOG015

        # Trunca o contexto para evitar exceder o limite de tokens
        historico_str = str(state.get("dados_historico", ""))[:4000]
        manuais_str = str(state.get("dados_manuais", ""))[:4000]

        prompt = ChatPromptTemplate.from_template(
            """Você é um analista de sistemas sênior. Com base nas informações coletadas, gere um diagnóstico técnico detalhado.

            <contexto>
            Solicitação Original: {solicitacao}
            Classificação: {classificacao}
            Dados do Histórico (RESUMIDO): {historico}
            Dados de RCM Específico: {rcm_especifico}
            Dados dos Manuais (RESUMIDO): {manuais}
            </contexto>

            <instrucoes>
            Pense passo a passo (Chain-of-Thought) antes de responder.

            1. Se Classificação == 'Solicitação de Melhoria':
               - Descreva a necessidade de negócio.
               - Liste os Requisitos Técnicos (telas, campos, APIs).
               - Identifique impactos no sistema.

            2. Se Classificação == 'Relato de Erro' ou 'Dúvida de Procedimento':
               - Analise o comportamento inesperado.
               - Identifique a Causa Raiz (dados, regra, procedimento incorreto).
            </instrucoes>

            Diagnóstico Técnico Detalhado:"""
        )
        chain = prompt | self.llm
        diagnostico_str = chain.invoke(
            {
                "solicitacao": state["solicitacao_original"],
                "classificacao": state["classificacao"],
                "historico": historico_str,
                "rcm_especifico": state["dados_rcm_especifico"]
                or "Nenhum RCM específico mencionado.",
                "manuais": manuais_str,
            }
        ).content
        return {"diagnostico": diagnostico_str}

    def gerar_relatorio_final(self, state: WorkflowState):  # noqa: ANN201
        logging.info("Passo 5: Gerando relatório final...")  # noqa: LOG015
        structured_llm = self.llm.with_structured_output(RelatorioAnalise)
        from datetime import datetime

        data_atual = datetime.now().strftime("%d/%m/%Y")

        prompt = ChatPromptTemplate.from_template(
            """Gere um relatório de análise estruturado com base em todo o contexto. Ignore o campo `solicitacao_id`.

            **CONTEXTO TEMPORAL:**
            - Data Atual: {data_atual}
            - Todas as estimativas de data devem ser calculadas a partir desta data.

            <contexto>
            Solicitação Original: {solicitacao}
            Classificação: {classificacao}
            Dados de RCM Específico: {rcm_especifico}
            Diagnóstico Técnico: {diagnostico}
            </contexto>

            <regras_sisp>
            {dados_metricas}
            </regras_sisp>

            Instruções para preenchimento:
            1.  **tipo_problema**: Use a classificação fornecida.
            2.  **tipo_solicitacao**: Classifique como 'Evolutivo', 'Corretivo', 'Operacao', etc.
            3.  **resumo_problema**: Resumo conciso.
            4.  **diagnostico**: Use o diagnóstico técnico fornecido.
            5.  **complexidade**: Classifique como 'Baixa', 'Média', 'Alta' ou 'Ultra'.
            6.  **solucao_sugerida**: Descreva a solução técnica.
            7.  **esforco_resolucao_dias**: Estime dias úteis com base na complexidade (Baixa=0-2, Média=3-7, Alta=8-15, Ultra=15-30).
            8.  **detalhes_evolutiva**: SE E SOMENTE SE for 'Melhoria' ou 'Evolutivo':
                - **estimativa_pontos_funcao**: Identifique as funções (ALI, AIE, EE, SE, CE) implícitas na solução sugerida. Consulte a **Tabela 1** e **Tabela 2/3** nas <regras_sisp> para somar os PFs.
                - **prazo_dias_uteis**: Use a **Tabela 4** nas <regras_sisp> com o total de PF calculado.
                - **data_prevista_entrega**: Data Atual + prazo_dias_uteis (apenas dias úteis).
            9.  **nivel_esforco**: Combine complexidade e PF para definir (Baixo, Médio, Alto)."""
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
                    "dados_metricas": state.get(
                        "dados_metricas", "Nenhuma métrica específica encontrada."
                    ),
                    "data_atual": data_atual,
                }
            )
            return {"relatorio_final": relatorio}  # noqa: TRY300
        except OutputParserException as e:
            logging.exception("Falha ao parsear a saída do LLM: %s", e)  # noqa: LOG015, TRY401
            # Retorna um estado de erro ou um relatório parcial
            return {
                "relatorio_final": RelatorioAnalise(
                    solicitacao_id=-1,
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

    def _registrar_detalhes_evolutiva(
        self, solicitacao_id: int, detalhes: DetalhesEvolutiva
    ) -> None:
        """Salva os detalhes da análise evolutiva no grafo."""
        logging.info(
            f"Registrando detalhes evolutivos para a solicitação {solicitacao_id}..."
        )
        query = """
        MATCH (s:Solicitacao {id: $solicitacao_id})
        CREATE (de:DetalhesEvolutiva {
            data_prevista_entrega: $data_prevista_entrega,
            estimativa_pontos_funcao: $estimativa_pontos_funcao,
            prazo_dias_uteis: $prazo_dias_uteis
        })
        MERGE (s)-[:TEM_DETALHES_EVOLUTIVA]->(de)
        """
        self.db_graph.query(
            query,
            params={
                "solicitacao_id": solicitacao_id,
                **detalhes.model_dump(),
            },
        )

    async def finalizar_analise(self, state: WorkflowState):  # noqa: ANN201
        """
        Passo 6: Finaliza a análise, gera RCM se necessário e atualiza labels no GitHub.
        """
        logging.info("Passo 6: Finalizando análise e gerando artefatos...")
        relatorio = state.get("relatorio_final")

        if not relatorio:
            logging.warning("Relatório incompleto. Pulando geração de RCM.")
            return {"relatorio_final": relatorio}

        # Tenta obter o ID do estado se não estiver no relatório
        issue_number = relatorio.solicitacao_id
        if not issue_number and state.get("solicitacao_id"):
            issue_number = state.get("solicitacao_id")
            relatorio.solicitacao_id = issue_number

        if not issue_number:
            logging.warning("ID da solicitação não encontrado. Pulando geração de RCM.")
            return {"relatorio_final": relatorio}

        # Verifica se é Evolutiva/Melhoria para gerar RCM
        # Normaliza para lowercase para comparação
        tipo_solicitacao = relatorio.tipo_solicitacao.lower()
        if "evoluti" in tipo_solicitacao or "melhoria" in tipo_solicitacao:
            logging.info(f"Solicitação {issue_number} é Evolutiva. Gerando RCM...")

            # Prepara dados para o RCM
            analysis_data = relatorio.model_dump()

            try:
                # Gera e anexa o RCM
                # Importação local para evitar ciclo se houver, mas idealmente no topo
                from src.services.github_service import update_issue_labels
                from src.services.rcm_generation_service import (
                    generate_and_attach_rcm_document,
                )

                template_path = "data/templates/SysRH - RCM - Relatório de Controle de Mudança - MOD - 9999-9999.docx"

                await generate_and_attach_rcm_document(
                    issue_number=issue_number,
                    analysis_data=analysis_data,
                    file_template_path=template_path,
                )

                # Atualiza labels
                await update_issue_labels(
                    issue_number=issue_number,
                    add_labels=["status:aguardando-validacao-rcm"],
                    remove_labels=["status:analise-em-andamento", "status:nova"],
                )
                logging.info(
                    f"RCM gerado e labels atualizadas para issue #{issue_number}."
                )

            except Exception as e:
                logging.exception(f"Erro ao gerar RCM ou atualizar GitHub: {e}")

        return {"relatorio_final": relatorio}

    def _build_graph(self) -> StateGraph:
        """Constrói e compila o workflow do LangGraph."""
        workflow = StateGraph(WorkflowState)

        # Adiciona os nós (passos) do workflow
        workflow.add_node("classificar_solicitacao", self.classificar_solicitacao)
        workflow.add_node("identificar_e_buscar_rcm", self.identificar_e_buscar_rcm)
        workflow.add_node("buscar_no_historico", self.buscar_no_historico)
        workflow.add_node("consultar_manuais", self.consultar_manuais)
        workflow.add_node("consultar_metricas", self.consultar_metricas)
        workflow.add_node("gerar_diagnostico", self.gerar_diagnostico)
        workflow.add_node("gerar_relatorio_final", self.gerar_relatorio_final)
        workflow.add_node("finalizar_analise", self.finalizar_analise)

        # Define as arestas (fluxo) do workflow
        workflow.set_entry_point("classificar_solicitacao")
        workflow.add_edge("classificar_solicitacao", "identificar_e_buscar_rcm")
        workflow.add_edge("identificar_e_buscar_rcm", "buscar_no_historico")
        workflow.add_edge("buscar_no_historico", "consultar_manuais")
        workflow.add_edge("consultar_manuais", "consultar_metricas")
        workflow.add_edge("consultar_metricas", "gerar_diagnostico")
        workflow.add_edge("gerar_diagnostico", "gerar_relatorio_final")
        workflow.add_edge("gerar_relatorio_final", "finalizar_analise")
        workflow.add_edge("finalizar_analise", END)

        return workflow.compile()

    async def arun(
        self, solicitacao: str, solicitacao_id: int | None = None
    ) -> RelatorioAnalise:
        """Executa o workflow completo de forma assíncrona."""
        initial_state: WorkflowState = {
            "solicitacao_original": solicitacao,
            "solicitacao_id": solicitacao_id,
            "classificacao": None,
            "dados_historico": None,
            "dados_rcm_especifico": None,
            "dados_manuais": None,
            "dados_metricas": None,
            "diagnostico": None,
            "relatorio_final": None,
        }
        final_state = await self.graph.ainvoke(initial_state)
        relatorio_final = final_state.get("relatorio_final")

        # Se não foi passado ID, tenta buscar no grafo (fallback)
        if not solicitacao_id:
            solicitacao_id = self._buscar_solicitacao_por_texto(solicitacao)

        if relatorio_final:
            relatorio_final.solicitacao_id = solicitacao_id

        if (
            relatorio_final
            and relatorio_final.detalhes_evolutiva
            and solicitacao_id != -1
        ):
            self._registrar_detalhes_evolutiva(
                solicitacao_id, relatorio_final.detalhes_evolutiva
            )

        return relatorio_final

    def run(self, solicitacao: str) -> RelatorioAnalise:
        """Executa o workflow completo para uma dada solicitação."""
        # Inicializa o estado com todas as chaves para satisfazer o type checker.

        # invoke pode falhar se tiver nós async. O ideal é usar arun.
        # Mas para manter compatibilidade, tentamos invoke.
        # Se finalizar_analise for async, invoke deve lidar se o runtime permitir,
        # mas geralmente requer ainvoke.
        # Vamos assumir que quem chama run() sabe o que faz ou que o LangGraph lida com isso.
        # Caso contrário, teríamos que rodar o loop aqui.
        import asyncio

        try:
            loop = asyncio.get_event_loop()
        except RuntimeError:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)

        return loop.run_until_complete(self.arun(solicitacao))


if __name__ == "__main__":
    # Exemplo de uso alinhado à Fase 2
    import asyncio

    from rag_sysrh.main import get_tools

    analista_agent = AnalistaWorkflow(tools=get_tools())

    texto_solicitacao = "Estou tentando registrar uma proposta de consignação para o cliente UDESC, mas o sistema apresenta o erro 'RN005 - Limite excedido'. O que devo fazer?"  # noqa: E501

    # Usando arun para suportar async
    relatorio = asyncio.run(analista_agent.arun(texto_solicitacao))

    print("\n--- Relatório de Análise da Solicitação ---")
    if relatorio:
        # Corrigido para usar os nomes de atributo corretos do modelo RelatorioAnalise
        print(f"Classificação: {relatorio.tipo_problema}")
        print(f"Resumo: {relatorio.resumo_problema}")
        print(f"Diagnóstico: {relatorio.diagnostico}")
        print(f"Solução Sugerida: {relatorio.solucao_sugerida}")
        print(f"Nível de Esforço: {relatorio.nivel_esforco}")
    else:
        print("Relatório não gerado.")

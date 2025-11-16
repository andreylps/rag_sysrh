import logging
import os
from typing import cast

from dateutil.parser import parse
from dotenv import load_dotenv
from langchain_core.prompts import ChatPromptTemplate
from langchain_neo4j import Neo4jGraph
from langchain_openai import ChatOpenAI
from pydantic import BaseModel, Field

# Configura o logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


class AvaliacaoQualidade(BaseModel):
    """
    Modelo de dados para a avaliação de qualidade de uma solicitação.
    """

    clareza_score: int = Field(
        description="Uma nota de 1 a 5 para a clareza da solicitação (1=muito ambíguo, 5=muito claro)."  # noqa: E501
    )
    completude_score: int = Field(
        description="Uma nota de 1 a 5 para a completude da solicitação (1=faltam muitas informações, 5=completa)."  # noqa: E501
    )
    pontos_ambiguos: list[str] = Field(
        description="Uma lista de frases ou perguntas que destacam pontos ambíguos ou que precisam de esclarecimento."  # noqa: E501
    )
    sugestoes_melhoria: list[str] = Field(
        description="Uma lista de sugestões para melhorar a descrição da solicitação."
    )


class AvaliacaoRCM(BaseModel):
    """
    Modelo de dados para a avaliação de conformidade de um RCM com sua solicitação original.
    """  # noqa: E501

    conformidade_score: int = Field(
        description="Nota de 1 a 5 para a conformidade do RCM com a solicitação (1=incompleto, 5=atende totalmente)."  # noqa: E501
    )
    pontos_faltantes: list[str] = Field(
        description="Lista de requisitos da solicitação original que não foram abordados no RCM."  # noqa: E501
    )
    analise_conformidade: str = Field(
        description="Um texto resumindo a análise de conformidade entre a solicitação e o RCM."  # noqa: E501
    )


class AvaliacaoEntrega(BaseModel):
    """
    Modelo de dados para a avaliação da entrega final de um RCM contra os critérios de aceite.
    """  # noqa: E501

    aderencia_score: int = Field(
        description="Nota de 1 a 5 para a aderência da entrega aos critérios de aceite da solicitação (1=baixa, 5=total)."  # noqa: E501
    )
    desvios_encontrados: list[str] = Field(
        description="Lista de desvios ou requisitos não atendidos na entrega final."
    )
    analise_final: str = Field(
        description="Um parecer final sobre a qualidade e completude da entrega."
    )


class AgenteQualidade:
    """
    Agente autônomo para monitorar e analisar a qualidade das solicitações.
    """

    def __init__(self) -> None:
        load_dotenv()
        self.llm = ChatOpenAI(model="gpt-4-turbo", temperature=0)
        self.graph = Neo4jGraph(
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
        )

    def _buscar_solicitacoes_nao_analisadas(self) -> list[dict]:
        """Busca no grafo por solicitações que ainda não têm uma análise de qualidade."""  # noqa: E501
        logging.info("Buscando solicitações não analisadas...")  # noqa: LOG015
        query = """
        MATCH (s:Solicitacao)
        WHERE NOT (s)-[:AVALIADO_POR]->(:AnaliseDeQualidade)
        RETURN s.id AS id, s.description AS descricao
        LIMIT 10 // Limita a 10 por execução para controle
        """
        return self.graph.query(query)

    def _analisar_solicitacao(self, texto_solicitacao: str) -> AvaliacaoQualidade:
        """Usa um LLM para avaliar a qualidade de uma solicitação."""
        structured_llm = self.llm.with_structured_output(
            AvaliacaoQualidade, method="function_calling"
        )
        prompt = ChatPromptTemplate.from_template(
            """Você é um Analista de Qualidade de Requisitos de Software.
            Sua tarefa é analisar a seguinte solicitação de usuário e avaliar sua clareza e completude.

            **Solicitação:**
            {solicitacao}

            **Instruções:**
            1.  **Clareza:** Avalie se a solicitação é fácil de entender. Dê uma nota de 1 (muito confusa) a 5 (perfeitamente clara).
            2.  **Completude:** Avalie se a solicitação contém todas as informações necessárias para um desenvolvedor começar a trabalhar. Dê uma nota de 1 (muito incompleta) a 5 (muito completa).
            3.  **Pontos Ambíguos:** Liste perguntas específicas que um analista precisaria fazer para esclarecer a solicitação.
            4.  **Sugestões de Melhoria:** Forneça sugestões concretas de como o texto da solicitação poderia ser melhorado."""  # noqa: E501
        )
        chain = prompt | structured_llm
        return cast(
            "AvaliacaoQualidade", chain.invoke({"solicitacao": texto_solicitacao})
        )

    def _registrar_analise(
        self, solicitacao_id: int, avaliacao: AvaliacaoQualidade
    ) -> None:
        """Salva o resultado da análise de volta no grafo."""
        logging.info(f"Registrando análise para a solicitação ID {solicitacao_id}...")  # noqa: G004, LOG015
        query = """
        MATCH (s:Solicitacao {id: $solicitacao_id})
        CREATE (a:AnaliseDeQualidade {
            clareza: $clareza,
            completude: $completude,
            pontos_ambiguos: $pontos_ambiguos,
            sugestoes: $sugestoes
        })
        MERGE (s)-[:AVALIADO_POR]->(a)
        """
        self.graph.query(
            query,
            params={
                "solicitacao_id": solicitacao_id,
                "clareza": avaliacao.clareza_score,
                "completude": avaliacao.completude_score,
                "pontos_ambiguos": avaliacao.pontos_ambiguos,
                "sugestoes": avaliacao.sugestoes_melhoria,
            },
        )

    def _buscar_rcms_nao_avaliados(self) -> list[dict]:
        """Busca RCMs que ainda não foram validados contra suas solicitações."""
        logging.info("Buscando RCMs não avaliados...")  # noqa: LOG015
        query = """
        // Estágio 1: Monitora RCMs aguardando aprovação
        MATCH (rcm:RCM)-[:ORIGINADO_DE]->(s:Solicitacao)
        WHERE toLower(rcm.status) = 'aguardando aprovação'
          AND NOT (rcm)-[:AVALIADO_POR]->(:AvaliacaoRCM)
        RETURN rcm.id AS rcm_id, rcm.description AS rcm_texto, s.texto_completo AS solicitacao_texto, s.effort AS esforco_solicitacao, rcm.pontos_funcao AS pontos_funcao_rcm
        LIMIT 5 // Limita para controle
        """  # noqa: E501
        return self.graph.query(query)

    def _analisar_conformidade_rcm(
        self, solicitacao_texto: str, rcm_texto: str
    ) -> AvaliacaoRCM:
        """Usa um LLM para avaliar se o RCM atende à solicitação original."""
        structured_llm = self.llm.with_structured_output(
            AvaliacaoRCM, method="function_calling"
        )
        prompt = ChatPromptTemplate.from_template(
            """Você é um Analista de Qualidade e Negócios Sênior.
            Sua tarefa é validar uma RCM (Requisição de Mudança) que está "Aguardando Aprovação". Avalie a conformidade do escopo e dos pontos de função.

            **Solicitação Original:**
            {solicitacao}

            **Descrição do RCM (Requisição de Mudança):**
            {rcm}

            **Dados de Esforço:**
            - Esforço Estimado na Solicitação (PF): {esforco_solicitacao}
            - Pontos de Função do RCM: {pontos_funcao_rcm}

            **Instruções de Análise:**
            1.  **Conformidade de Escopo e Esforço:** Compare os requisitos da solicitação com o escopo do RCM. Verifique se a estimativa de Pontos de Função do RCM é compatível com o esforço original e o escopo descrito. Dê uma nota de 1 (incompatível) a 5 (perfeitamente alinhado).
            2.  **Pontos Faltantes:** Liste objetivamente quaisquer pontos, requisitos ou partes da solicitação original que parecem não ter sido incluídos ou abordados na descrição do RCM. Se tudo foi atendido, retorne uma lista vazia.
            3.  **Análise de Conformidade:** Escreva um breve parágrafo explicando sua avaliação, destacando a cobertura dos requisitos e a coerência da estimativa de esforço.
            """  # noqa: E501
        )
        chain = prompt | structured_llm
        return cast(
            "AvaliacaoRCM",
            chain.invoke({"solicitacao": solicitacao_texto, "rcm": rcm_texto}),
        )

    def _registrar_avaliacao_rcm(self, rcm_id: int, avaliacao: AvaliacaoRCM) -> None:
        """Salva o resultado da avaliação de conformidade do RCM no grafo."""
        logging.info(f"Registrando avaliação de conformidade para o RCM ID {rcm_id}...")  # noqa: G004, LOG015
        query = """
        MATCH (rcm:RCM {id: $rcm_id})
        CREATE (ar:AvaliacaoRCM {
            conformidade_score: $conformidade_score,
            pontos_faltantes: $pontos_faltantes,
            analise: $analise
        })
        MERGE (rcm)-[:AVALIADO_POR]->(ar)
        """
        self.graph.query(
            query,
            params={
                "rcm_id": rcm_id,
                "conformidade_score": avaliacao.conformidade_score,
                "pontos_faltantes": avaliacao.pontos_faltantes,
                "analise": avaliacao.analise_conformidade,
            },
        )

    def executar_ciclo(self) -> str | None:
        """Executa um ciclo completo de busca, análise e registro."""
        # Verifica se os dados necessários para as análises existem
        has_rcm_data = self.graph.query("MATCH (n:RCM) RETURN n LIMIT 1")
        if not has_rcm_data:
            return (
                "⚠️ Dados insuficientes para o Agente de Qualidade! Para habilitar as análises de conformidade, prazos e entregas, providencie os seguintes arquivos na pasta 'data/' e execute a ingestão de dados:\n"  # noqa: E501
                "   - 📂 **Arquivo**: `rcms.csv`\n"
                "     **Descrição**: Contém os dados das Requisições de Mudança (RCMs).\n"  # noqa: E501
                "     **Colunas essenciais**: `id`, `description`, `status`, `id_solicitacao` (para ligar ao chamado original), `pontos_funcao`, `data_prevista_entrega`.\n\n"  # noqa: E501
                "   - 📂 **Arquivo**: `casos_de_teste.csv` (Opcional, para validação de entregas)\n"  # noqa: E501
                "     **Descrição**: Detalha os casos de teste associados a cada RCM.\n"
                "     **Colunas essenciais**: `id_rcm` (para ligar à RCM), `nome`, `status` (ex: 'sucesso', 'falha')."  # noqa: E501
            )

        # Ciclo 1: Analisar a qualidade de novas solicitações
        solicitacoes = self._buscar_solicitacoes_nao_analisadas()
        if not solicitacoes:
            logging.info("Nenhuma nova solicitação para analisar.")  # noqa: LOG015

        for solicitacao in solicitacoes:
            solicitacao_id = solicitacao["id"]
            descricao = solicitacao.get("descricao") or ""
            logging.info(f"Analisando solicitação ID: {solicitacao_id}")  # noqa: G004, LOG015

            avaliacao = self._analisar_solicitacao(descricao)
            self._registrar_analise(solicitacao_id, avaliacao)

        logging.info("Ciclo de análise de qualidade de solicitações concluído.")  # noqa: LOG015

        # Ciclo 2: Validar a conformidade de RCMs gerados
        rcms_para_avaliar = self._buscar_rcms_nao_avaliados()
        if not rcms_para_avaliar:
            logging.info("Nenhum novo RCM para validar.")  # noqa: LOG015
        else:
            for rcm in rcms_para_avaliar:
                logging.info(f"Validando conformidade do RCM ID: {rcm['rcm_id']}")  # noqa: G004, LOG015
                avaliacao = self._analisar_conformidade_rcm(
                    rcm["solicitacao_texto"], rcm["rcm_texto"]
                )
                self._registrar_avaliacao_rcm(rcm["rcm_id"], avaliacao)
        logging.info("Ciclo de validação de conformidade de RCMs concluído.")  # noqa: LOG015

        # Ciclo 3: Monitorar prazos de desenvolvimento
        self._verificar_prazos_e_gerar_alertas()

        # Ciclo 4: Validar entrega final contra critérios de aceite
        self._validar_entrega_final()

        # Ciclo 5: Validar aceite em produção
        self._validar_aceite_producao()
        return None

    def _verificar_prazos_e_gerar_alertas(self) -> None:
        """Busca RCMs com prazos próximos ou vencidos e gera alertas."""
        logging.info("Iniciando ciclo de verificação de prazos de RCMs...")  # noqa: LOG015
        # Esta query assume que a data está no formato 'YYYY-MM-DD'
        query = """
        MATCH (rcm:RCM)
        WHERE rcm.data_prevista_entrega IS NOT NULL
          AND NOT toLower(rcm.status) IN ['concluído', 'entregue', 'cancelado']
          AND NOT (rcm)-[:TEM_ALERTA]->(:AlertaPrazo) // Evita alertar novamente
        WITH rcm, date(rcm.data_prevista_entrega) AS prazo
        // Alerta se o prazo for nos próximos 7 dias ou se já passou
        WHERE prazo < date() + duration({days: 7})
        RETURN rcm.id AS rcm_id, rcm.data_prevista_entrega AS data_prevista
        """
        rcms_em_risco = self.graph.query(query)

        if not rcms_em_risco:
            logging.info("Nenhum RCM com prazo em risco encontrado.")  # noqa: LOG015
            return

        for rcm in rcms_em_risco:
            rcm_id = rcm["rcm_id"]
            data_prevista_str = rcm["data_prevista"]
            try:
                data_prevista = parse(data_prevista_str).date()
                hoje = parse(
                    self.graph.query("RETURN date() AS today")[0]["today"]
                ).date()
                dias_restantes = (data_prevista - hoje).days

                if dias_restantes < 0:
                    mensagem = f"Atenção: O prazo de entrega está vencido há {-dias_restantes} dia(s)."  # noqa: E501
                else:
                    mensagem = f"Atenção: O prazo de entrega se encerra em {dias_restantes} dia(s)."  # noqa: E501

                self._registrar_alerta_prazo(rcm_id, data_prevista_str, mensagem)

            except (ValueError, TypeError) as e:
                logging.exception(f"Erro ao processar data para o RCM ID {rcm_id}: {e}")  # noqa: G004, LOG015, TRY401

        logging.info("Ciclo de verificação de prazos concluído.")  # noqa: LOG015

    def _registrar_alerta_prazo(
        self, rcm_id: int, data_prevista: str, mensagem: str
    ) -> None:
        """Cria um nó de AlertaPrazo e o conecta ao RCM."""
        logging.info(f"Registrando alerta de prazo para o RCM ID {rcm_id}...")  # noqa: G004, LOG015
        query = """
        MATCH (rcm:RCM {id: $rcm_id})
        CREATE (al:AlertaPrazo {
            mensagem: $mensagem,
            data_alerta: date(),
            data_prevista_rcm: date($data_prevista)
        })
        MERGE (rcm)-[:TEM_ALERTA]->(al)
        """
        self.graph.query(
            query,
            params={
                "rcm_id": rcm_id,
                "mensagem": mensagem,
                "data_prevista": data_prevista,
            },
        )

    def _validar_entrega_final(self) -> None:
        """Verifica se RCMs concluídos atendem aos critérios da solicitação original."""
        logging.info("Iniciando ciclo de validação de entregas finais...")  # noqa: LOG015
        # Estágio 2: Monitora RCMs em fase de homologação
        query = """
        MATCH (rcm:RCM)-[:ORIGINADO_DE]->(s:Solicitacao)
        WHERE toLower(rcm.status) = 'aceite homologação'
          AND NOT (rcm)-[:AVALIADO_EM_ENTREGA_POR]->(:AvaliacaoEntrega)
        // Coleta informações sobre os testes associados
        OPTIONAL MATCH (rcm)-[:TEM_TESTE]->(t:CasoDeTeste)
        WITH rcm, s, COLLECT({nome: t.nome, status: t.status}) AS testes
        RETURN rcm.id AS rcm_id, s.texto_completo AS solicitacao_texto, rcm.description AS rcm_texto
        LIMIT 5
        """  # noqa: E501
        rcms_concluidos = self.graph.query(query)

        if not rcms_concluidos:
            logging.info("Nenhum RCM concluído para validar a entrega.")  # noqa: LOG015
            return

        for rcm in rcms_concluidos:
            rcm_id = rcm["rcm_id"]
            logging.info(f"Validando entrega do RCM ID: {rcm_id}")  # noqa: G004, LOG015
            avaliacao = self._analisar_aderencia_entrega(
                rcm["solicitacao_texto"], rcm["rcm_texto"]
            )
            self._registrar_avaliacao_entrega(rcm_id, avaliacao)

        logging.info("Ciclo de validação de entregas concluído.")  # noqa: LOG015

    def _analisar_aderencia_entrega(
        self, solicitacao_texto: str, rcm_texto: str
    ) -> AvaliacaoEntrega:
        """Usa um LLM para avaliar a aderência da entrega aos critérios de aceite."""
        structured_llm = self.llm.with_structured_output(
            AvaliacaoEntrega, method="function_calling"
        )
        prompt = ChatPromptTemplate.from_template(
            """Você é um Engenheiro de QA (Quality Assurance) Sênior, especialista em homologação.
            Sua tarefa é validar se a entrega de uma RCM, que está em "Aceite Homologação", atende aos critérios da solicitação e se os testes foram bem-sucedidos.

            **Solicitação Original (Critérios de Aceite):**
            {solicitacao}

            **Descrição do RCM Entregue (O que foi feito):**
            {rcm}

            **Resultados dos Testes Automatizados:**
            {testes}

            **Instruções de Validação:**
            1.  **Aderência:** Compare os critérios da solicitação com o que foi entregue no RCM. Verifique se todos os testes listados tiveram status 'sucesso'. Dê uma nota de 1 (não atende/testes falharam) a 5 (atende perfeitamente/testes OK).
            2.  **Desvios Encontrados:** Liste objetivamente quaisquer requisitos não cumpridos ou testes que falharam. Se tudo estiver correto, retorne uma lista vazia.
            3.  **Análise Final:** Escreva um parecer técnico sobre a qualidade da entrega para homologação. Se houver falhas nos testes, a aprovação deve ser negada.
            """  # noqa: E501
        )
        chain = prompt | structured_llm
        return cast(
            "AvaliacaoEntrega",
            chain.invoke({"solicitacao": solicitacao_texto, "rcm": rcm_texto}),
        )

    def _registrar_avaliacao_entrega(
        self, rcm_id: int, avaliacao: AvaliacaoEntrega
    ) -> None:
        """Salva o resultado da validação da entrega no grafo."""
        logging.info(f"Registrando validação de entrega para o RCM ID {rcm_id}...")  # noqa: G004, LOG015
        query = """
        MATCH (rcm:RCM {id: $rcm_id})
        CREATE (ae:AvaliacaoEntrega {
            aderencia_score: $aderencia_score,
            desvios_encontrados: $desvios,
            analise_final: $analise
        })
        MERGE (rcm)-[:AVALIADO_EM_ENTREGA_POR]->(ae)
        """
        self.graph.query(
            query,
            params={
                "rcm_id": rcm_id,
                "aderencia_score": avaliacao.aderencia_score,
                "desvios": avaliacao.desvios_encontrados,
                "analise": avaliacao.analise_final,
            },
        )

    def _validar_aceite_producao(self) -> None:
        """Valida a entrega final no estágio de aceite em produção."""
        logging.info("Iniciando ciclo de validação de aceite em produção...")  # noqa: LOG015
        # Estágio 3: Monitora RCMs em fase de aceite em produção
        query = """
        MATCH (rcm:RCM)
        WHERE toLower(rcm.status) = 'aceite produção'
          AND NOT (rcm)-[:VALIDADO_EM_PRODUCAO_POR]->(:ValidacaoProducao)
        RETURN rcm.id AS rcm_id
        LIMIT 5
        """
        rcms_para_validar = self.graph.query(query)

        if not rcms_para_validar:
            logging.info("Nenhum RCM em aceite de produção para validar.")  # noqa: LOG015
            return

        for rcm in rcms_para_validar:
            rcm_id = rcm["rcm_id"]
            logging.info(  # noqa: LOG015
                f"Registrando validação final de produção para o RCM ID: {rcm_id}"  # noqa: G004
            )
            # Para este estágio, vamos apenas registrar a validação, mas a lógica pode ser expandida  # noqa: E501
            self.graph.query(
                "MATCH (rcm:RCM {id: $rcm_id}) CREATE (vp:ValidacaoProducao {data: date()}) MERGE (rcm)-[:VALIDADO_EM_PRODUCAO_POR]->(vp)",  # noqa: E501
                params={"rcm_id": rcm_id},
            )

        logging.info("Ciclo de validação de aceite em produção concluído.")  # noqa: LOG015


if __name__ == "__main__":
    agente = AgenteQualidade()
    agente.executar_ciclo()

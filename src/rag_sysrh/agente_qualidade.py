import logging
import uuid
from typing import Any, Dict, List

from langchain_core.exceptions import OutputParserException
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
from pydantic import BaseModel, Field, ValidationError

from rag_sysrh.base_agent import BaseAgent

# Configura o logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


class AvaliacaoRCM(BaseModel):
    """Modelo de dados para a avaliação de conformidade de uma RCM."""

    conformidade: bool = Field(
        description="Indica se a RCM está em conformidade com os padrões (True/False)."
    )
    justificativa: str = Field(
        description="Uma justificativa detalhada para a avaliação de conformidade."
    )


class AvaliacaoEntrega(BaseModel):
    """
    Modelo de dados para a avaliação da qualidade de uma entrega (RCM).
    """

    status_geral: str = Field(
        description="O status geral da entrega da RCM, baseado nos casos de teste (APROVADO, REPROVADO, PENDENTE)."
    )
    resumo_qualidade: str = Field(
        description="Um resumo conciso da qualidade da entrega, destacando pontos fortes e fracos."
    )
    recomendacoes: str = Field(
        description="Recomendações para melhorias futuras ou ações corretivas."
    )


class AvaliacaoPrazo(BaseModel):
    """Modelo de dados para a avaliação de prazo de uma RCM."""

    no_prazo: bool = Field(
        description="Indica se a RCM foi entregue dentro do prazo (True/False)."
    )
    dias_atraso: int = Field(
        description="Número de dias de atraso (0 se entregue no prazo ou adiantado)."
    )
    data_prevista: str = Field(description="Data prevista para entrega (ISO 8601).")
    data_real: str = Field(description="Data real de conclusão (ISO 8601).")


class AgenteQualidade(BaseAgent):
    """
    Agente autônomo para avaliar a qualidade das entregas (RCMs)
    com base nos resultados dos casos de teste.
    """

    _CONFORMITY_PROMPT_TEMPLATE = """Você é um Auditor de Qualidade de Software. Sua tarefa é analisar os metadados de uma Requisição de Mudança (RCM) para garantir que ela siga os padrões de documentação.

            **Padrões de Conformidade:**
            1. O título da RCM DEVE conter um ID numérico da solicitação original (ex: "1451/2020").
            2. O status da RCM NÃO PODE ser "Novo" ou "Em Análise", pois ela já deveria ter sido processada.

            **Dados da RCM para Análise:**
            - Título: {titulo}
            - Status: {status}

            Com base nos padrões, avalie a conformidade da RCM.
            """

    def _registrar_avaliacao_conformidade(
        self, rcm_id: str, avaliacao: AvaliacaoRCM
    ) -> None:
        """Salva a avaliação de conformidade da RCM no grafo."""
        query_registro = """
        MATCH (rcm:RCM {id: $rcm_id})
        CREATE (ar:AvaliacaoRCM {
            id: randomUUID(),
            conformidade: $conformidade,
            justificativa: $justificativa,
            dataAvaliacao: datetime()
        })
        MERGE (rcm)-[:AVALIADA_POR_CONFORMIDADE]->(ar)
        """
        self.graph.query(
            query_registro,
            params={
                "rcm_id": rcm_id,
                "conformidade": avaliacao.conformidade,
                "justificativa": avaliacao.justificativa,
            },
        )

        # Lógica de Etiquetagem para Revisão (Human-in-the-Loop)
        if not avaliacao.conformidade:
            logging.warning(f"RCM {rcm_id} não conforme. Marcando para revisão.")
            self.graph.query(
                "MATCH (rcm:RCM {id: $rcm_id}) SET rcm:NeedsRevision",
                params={"rcm_id": rcm_id},
            )
        else:
            # Se estiver conforme, remove a flag de revisão caso exista (correção realizada)
            self.graph.query(
                "MATCH (rcm:RCM {id: $rcm_id}) REMOVE rcm:NeedsRevision",
                params={"rcm_id": rcm_id},
            )

        logging.info(f"Análise de conformidade registrada para a RCM {rcm_id}.")

    def executar_ciclo_conformidade_rcm(self, limit: int = 5) -> None:
        """
        Executa um ciclo de verificação de conformidade das RCMs.
        Este método representa a funcionalidade original do agente.

        Args:
            limit (int): O número máximo de RCMs a serem processadas.
        """
        logging.info("Iniciando ciclo de conformidade de RCM do Agente de Qualidade.")
        # Verifica se os dados necessários para as análises existem
        if not self.graph.query("MATCH (n:RCM) RETURN n LIMIT 1"):
            logging.warning(
                "Dados de RCM não encontrados. Pulando ciclo de conformidade."
            )
            return

        # Query para buscar RCMs que ainda não foram avaliadas
        query_busca = """
        MATCH (rcm:RCM)
        WHERE NOT (rcm)-[:AVALIADA_POR_CONFORMIDADE]->(:AvaliacaoRCM)
        RETURN rcm.id AS rcm_id, rcm.titulo AS rcm_titulo, rcm.status AS rcm_status
        LIMIT $limit
        """
        rcms_para_analise = self.graph.query(query_busca, params={"limit": limit})

        if not rcms_para_analise:
            logging.info("Nenhuma nova RCM para análise de conformidade encontrada.")
            return

        logging.info(
            f"Encontradas {len(rcms_para_analise)} RCMs para análise de conformidade."
        )

        structured_llm = self.llm.with_structured_output(AvaliacaoRCM)
        prompt = ChatPromptTemplate.from_template(self._CONFORMITY_PROMPT_TEMPLATE)
        chain = prompt | structured_llm

        for rcm in rcms_para_analise:
            try:
                avaliacao: AvaliacaoRCM = chain.invoke(
                    {"titulo": rcm["rcm_titulo"], "status": rcm["rcm_status"]}
                )
                self._registrar_avaliacao_conformidade(rcm["rcm_id"], avaliacao)
            except ValidationError as e:
                logging.error(
                    f"Erro de validação do Pydantic ao processar RCM {rcm['rcm_id']}: {e}"
                )
            except OutputParserException as e:
                logging.error(
                    f"Erro de parsing do LLM ao avaliar RCM {rcm['rcm_id']}: {e}"
                )
            except Exception as e:
                logging.error(
                    f"Falha ao processar a RCM {rcm['rcm_id']} para conformidade: {e}"
                )

        logging.info("Ciclo de conformidade de RCM finalizado.")

    def _buscar_rcms_para_validar(self) -> List[Dict[str, Any]]:
        """
        Busca RCMs que possuem casos de teste associados e que ainda não foram avaliadas
        pelo Agente de Qualidade.
        """
        logging.info("Buscando RCMs com casos de teste para validação...")
        query = """
        MATCH (rcm:RCM)-[:TEM_TESTE]->(ct:CasoDeTeste)
        WHERE NOT (rcm)-[:AVALIADA_POR_QUALIDADE]->(:AvaliacaoEntrega)
        RETURN DISTINCT rcm.id AS rcm_id, rcm.titulo AS rcm_title
        LIMIT 10
        """
        return self.graph.query(query)

    def _obter_casos_de_teste_da_rcm(self, rcm_id: str) -> List[Dict[str, Any]]:
        """
        Obtém todos os casos de teste associados a uma RCM específica.
        """
        query = """
        MATCH (rcm:RCM {id: $rcm_id})-[:TEM_TESTE]->(ct:CasoDeTeste)
        RETURN ct.id AS caso_teste_id, ct.descricao AS descricao, ct.status AS status
        """
        return self.graph.query(query, params={"rcm_id": rcm_id})

    def _avaliar_casos_de_teste_com_llm(
        self, rcm_title: str, test_cases: List[Dict[str, Any]]
    ) -> "AvaliacaoEntrega":
        """
        Usa um LLM para gerar uma avaliação da entrega da RCM com base nos casos de teste,
        usando o config de callbacks.
        """
        structured_llm = self.llm.with_structured_output(AvaliacaoEntrega)

        test_cases_str = "\n".join(
            [
                f"- ID: {tc['caso_teste_id']}, Descrição: {tc['descricao']}, Status: {tc['status']}"
                for tc in test_cases
            ]
        )

        prompt = ChatPromptTemplate.from_template(
            """Você é um Agente de Qualidade de Software. Sua tarefa é analisar os resultados
            de casos de teste para uma Requisição de Mudança (RCM) e fornecer uma avaliação
            concisa da qualidade da entrega.

            **RCM:** {rcm_title}

            **Casos de Teste e Seus Status:**
            {test_cases_str}

            **Instruções:**
            1.  **Formato de Saída:** Os nomes dos campos na saída JSON DEVEM estar em `snake_case` (ex: `status_geral`, `resumo_qualidade`).
            2.  Determine o 'status_geral' da entrega (APROVADO se todos os testes APROVADOS,
                REPROVADO se algum teste REPROVADO, PENDENTE se algum teste PENDENTE e nenhum REPROVADO).
            3.  Crie um 'resumo_qualidade' da entrega, destacando se a funcionalidade
                foi bem coberta pelos testes e se há preocupações.
            4.  Forneça 'recomendacoes' claras para melhorias ou próximas ações,
                especialmente se houver testes REPROVADOS ou PENDENTES.
            """
        )
        chain = prompt | structured_llm
        return chain.invoke({"rcm_title": rcm_title, "test_cases_str": test_cases_str})

    def _registrar_avaliacao_entrega(
        self, rcm_id: str, avaliacao: AvaliacaoEntrega, test_case_ids: List[str]
    ) -> None:
        """
        Salva a avaliação da entrega e seus relacionamentos no grafo.
        """
        logging.info(f"Registrando avaliação de entrega para a RCM ID {rcm_id}...")
        query = """
        MATCH (rcm:RCM {id: $rcm_id})
        CREATE (ae:AvaliacaoEntrega {
            id: $avaliacao_id,
            status_geral: $status_geral,
            resumo_qualidade: $resumo_qualidade,
            recomendacoes: $recomendacoes,
            dataAvaliacao: datetime()
        })
        MERGE (rcm)-[:AVALIADA_POR_QUALIDADE]->(ae)
        WITH ae, rcm
        UNWIND $test_case_ids AS ct_id
        MATCH (ct:CasoDeTeste {id: ct_id})
        MERGE (ae)-[:BASEADO_EM]->(ct)
        """
        self.graph.query(
            query,
            params={
                "rcm_id": rcm_id,
                "avaliacao_id": str(uuid.uuid4()),
                "status_geral": avaliacao.status_geral,
                "resumo_qualidade": avaliacao.resumo_qualidade,
                "recomendacoes": avaliacao.recomendacoes,
                "test_case_ids": test_case_ids,
            },
        )
        logging.info(f"Avaliação de entrega para RCM {rcm_id} registrada com sucesso.")

    def _registrar_avaliacao_prazo(
        self, rcm_id: str, avaliacao: AvaliacaoPrazo
    ) -> None:
        """Salva a avaliação de prazo da RCM no grafo."""
        query = """
        MATCH (rcm:RCM {id: $rcm_id})
        CREATE (ap:AvaliacaoPrazo {
            id: randomUUID(),
            no_prazo: $no_prazo,
            dias_atraso: $dias_atraso,
            data_prevista: $data_prevista,
            data_real: $data_real,
            dataAvaliacao: datetime()
        })
        MERGE (rcm)-[:AVALIADA_POR_PRAZO]->(ap)
        """
        self.graph.query(
            query,
            params={
                "rcm_id": rcm_id,
                "no_prazo": avaliacao.no_prazo,
                "dias_atraso": avaliacao.dias_atraso,
                "data_prevista": avaliacao.data_prevista,
                "data_real": avaliacao.data_real,
            },
        )
        logging.info(f"Avaliação de prazo registrada para a RCM {rcm_id}.")

    def executar_ciclo_prazo_rcm(self) -> None:
        """
        Verifica RCMs concluídas e compara a data real com a prevista.
        """
        logging.info("Iniciando ciclo de verificação de prazos de RCM.")

        # Busca RCMs com datas definidas e que ainda não foram avaliadas por prazo
        query = """
        MATCH (rcm:RCM)
        WHERE rcm.data_prevista_entrega IS NOT NULL 
          AND rcm.data_conclusao_real IS NOT NULL
          AND NOT (rcm)-[:AVALIADA_POR_PRAZO]->(:AvaliacaoPrazo)
        RETURN rcm.id AS rcm_id, rcm.data_prevista_entrega AS prevista, rcm.data_conclusao_real AS real
        LIMIT 50
        """
        rcms = self.graph.query(query)

        if not rcms:
            logging.info("Nenhuma RCM pendente de análise de prazo encontrada.")
            return
        from datetime import datetime

        for rcm in rcms:
            try:
                # As datas no Neo4j estão vindo como strings 'DD/MM/YYYY HH:MM'
                prevista_raw = str(rcm["prevista"])
                real_raw = str(rcm["real"])

                # Tenta limpar e parsear
                # Remove possíveis espaços extras
                prevista_str = prevista_raw.strip()
                real_str = real_raw.strip()

                # Formato observado: 13/02/2025 00:00
                dt_prevista = datetime.strptime(prevista_str, "%d/%m/%Y %H:%M")
                dt_real = datetime.strptime(real_str, "%d/%m/%Y %H:%M")

                dias_atraso = (dt_real - dt_prevista).days
                no_prazo = dias_atraso <= 0
                dias_atraso = max(0, dias_atraso)  # Não reportar atraso negativo

                avaliacao = AvaliacaoPrazo(
                    no_prazo=no_prazo,
                    dias_atraso=dias_atraso,
                    data_prevista=prevista_str,
                    data_real=real_str,
                )

                self._registrar_avaliacao_prazo(rcm["rcm_id"], avaliacao)

            except ValueError as ve:
                logging.error(
                    f"Erro de formato de data na RCM {rcm['rcm_id']}: {ve}. Esperado DD/MM/YYYY HH:MM."
                )
            except Exception as e:
                logging.error(f"Erro ao avaliar prazo da RCM {rcm['rcm_id']}: {e}")

        logging.info("Ciclo de verificação de prazos finalizado.")

    def executar_ciclo_validacao_entrega(self) -> None:
        """
        Executa um ciclo completo de validação de entregas (RCMs)
        com base nos casos de teste associados.
        """
        logging.info("Iniciando ciclo de validação de entrega do Agente de Qualidade.")

        if not self.graph.query("MATCH (n:CasoDeTeste) RETURN n LIMIT 1"):
            logging.warning(
                "Dados de Casos de Teste não encontrados. Pulando ciclo de validação de entrega."
            )
            return

        rcms_para_validar = self._buscar_rcms_para_validar()
        if not rcms_para_validar:
            logging.info("Nenhuma nova RCM com casos de teste para validar.")
            return

        logging.info(f"Encontradas {len(rcms_para_validar)} RCMs para validação.")

        for rcm_data in rcms_para_validar:
            rcm_id = rcm_data["rcm_id"]
            rcm_title = rcm_data["rcm_title"]

            try:
                test_cases = self._obter_casos_de_teste_da_rcm(rcm_id)
                if not test_cases:
                    logging.warning(
                        f"RCM {rcm_id} não possui casos de teste associados. Pulando validação."
                    )
                    continue

                logging.info(
                    f"Avaliando RCM {rcm_id} com {len(test_cases)} casos de teste."
                )
                avaliacao = self._avaliar_casos_de_teste_com_llm(rcm_title, test_cases)

                test_case_ids = [tc["caso_teste_id"] for tc in test_cases]
                self._registrar_avaliacao_entrega(rcm_id, avaliacao, test_case_ids)

            except Exception as e:
                logging.error(
                    f"Falha ao processar a RCM {rcm_id} para validação de entrega: {e}"
                )

        logging.info("Ciclo de validação de entrega do Agente de Qualidade finalizado.")

    def _gerar_relatorio_gerencial(
        self,
        avaliacoes_conformidade: List[Dict[str, Any]],
        avaliacoes_entrega: List[Dict[str, Any]],
        avaliacoes_prazo: List[Dict[str, Any]],
    ) -> str:
        """
        Usa um LLM para gerar um relatório gerencial consolidado em Markdown.
        """
        logging.info("Gerando relatório gerencial consolidado...")

        # Converte as listas de dicionários em strings formatadas para o prompt
        conformidade_str = "\n".join(
            [
                f"- RCM ID: {item.get('rcm_id')}, Título: {item.get('rcm_titulo')}, Conformidade: {item.get('avaliacao', {}).get('conformidade', 'N/A')}, Justificativa: {item.get('avaliacao', {}).get('justificativa', 'N/A')}"
                for item in avaliacoes_conformidade
            ]
        )
        entrega_str = "\n".join(
            [
                f"- RCM ID: {item.get('rcm_id')}, Título: {item.get('rcm_title')}, Status Geral: {item.get('avaliacao', {}).get('status_geral', 'N/A')}, Resumo: {item.get('avaliacao', {}).get('resumo_qualidade', 'N/A')}, Recomendações: {item.get('avaliacao', {}).get('recomendacoes', 'N/A')}"
                for item in avaliacoes_entrega
            ]
        )
        prazo_str = "\n".join(
            [
                f"- RCM ID: {item.get('rcm_id')}, Título: {item.get('rcm_titulo')}, No Prazo: {item.get('avaliacao', {}).get('no_prazo', 'N/A')}, Dias Atraso: {item.get('avaliacao', {}).get('dias_atraso', 'N/A')}, Prevista: {item.get('avaliacao', {}).get('data_prevista', 'N/A')}, Real: {item.get('avaliacao', {}).get('data_real', 'N/A')}"
                for item in avaliacoes_prazo
            ]
        )

        prompt = ChatPromptTemplate.from_template(
            """Você é um Gerente de QA Sênior. Sua tarefa é criar um relatório executivo em Markdown com base nos resultados dos ciclos de análise do Agente de Qualidade.

            **Dados da Análise de Conformidade de RCMs:**
            {conformidade_str}

            **Dados da Análise de Qualidade de Entregas (baseado em Casos de Teste):**
            {entrega_str}
            
            **Dados da Análise de Prazos de RCMs:**
            {prazo_str}

            **Instruções para o Relatório:**
            1.  **Título Principal:** Comece com `# Relatório do Ciclo de Qualidade`.
            2.  **Resumo Executivo:** Escreva um parágrafo inicial resumindo os principais achados do ciclo (quantas RCMs analisadas, quantos problemas encontrados, status geral de prazos, etc.).
            3.  **Seção de Análise de Conformidade:**
                - Use o subtítulo `## 📋 Análise de Conformidade de RCMs`.
                - Se houver RCMs não conformes, liste-as em uma subseção `### ⚠️ Pontos de Atenção`, usando bullet points. Para cada item, inclua o ID da RCM, a justificativa do problema e uma **Ação Recomendada** clara.
                - Se tudo estiver conforme, apenas mencione: "✅ Todas as RCMs analisadas estão em conformidade com os padrões."
            4.  **Seção de Análise de Qualidade de Entregas:**
                - Use o subtítulo `## 📦 Análise de Qualidade de Entregas`.
                - Se houver entregas com status 'REPROVADO' ou 'PENDENTE', liste-as em uma subseção `### ⚠️ Pontos de Atenção`. Para cada item, inclua o ID da RCM, o resumo do problema e a **Ação Recomendada**.
                - Se todas as entregas estiverem 'APROVADO', mencione: "✅ Todas as entregas analisadas foram aprovadas nos testes."
            5.  **Seção de Análise de Prazos:**
                - Use o subtítulo `## ⏱️ Análise de Prazos`.
                - Se houver RCMs com atraso (No Prazo = False), liste-as em uma subseção `### ⚠️ Entregas em Atraso`. Para cada item, mostre o ID, Título, Dias de Atraso e datas.
                - Se todas estiverem no prazo, mencione: "✅ Todas as entregas analisadas foram realizadas dentro do prazo."
            6.  **Conclusão:** Finalize com um breve parágrafo de conclusão sobre a saúde geral da qualidade no ciclo atual.

            Se uma das seções não tiver dados, apenas escreva "Nenhuma nova análise realizada neste ciclo." para essa seção.
            """
        )

        chain = prompt | self.llm | StrOutputParser()
        return chain.invoke(
            {
                "conformidade_str": conformidade_str,
                "entrega_str": entrega_str,
                "prazo_str": prazo_str,
            }
        )

    def executar_ciclo_gerencial(self, status_callback: Any = None) -> str:  # noqa: C901
        """
        Executa um ciclo completo de análise de qualidade e gera um relatório gerencial.

        Args:
            status_callback: Uma função opcional para receber atualizações de status.
        """
        if status_callback:
            status_callback("Iniciando ciclo gerencial...")
        logging.info("Iniciando ciclo gerencial completo do Agente de Qualidade.")

        # --- Coleta de Dados de Conformidade ---
        if status_callback:
            status_callback("Executando análise de conformidade de RCMs...")
        self.executar_ciclo_conformidade_rcm()  # Executa e salva no grafo
        # Busca os resultados para o relatório
        avaliacoes_conformidade_realizadas = self.graph.query(
            "MATCH (rcm:RCM)-[:AVALIADA_POR_CONFORMIDADE]->(a:AvaliacaoRCM) RETURN rcm.id as rcm_id, rcm.titulo as rcm_titulo, a as avaliacao"
        )

        # --- Coleta de Dados de Validação de Entrega ---
        if status_callback:
            status_callback("Executando validação de qualidade das entregas...")
        self.executar_ciclo_validacao_entrega()  # Executa e salva no grafo
        # Busca os resultados para o relatório
        avaliacoes_entrega_realizadas = self.graph.query(
            "MATCH (rcm:RCM)-[:AVALIADA_POR_QUALIDADE]->(a:AvaliacaoEntrega) RETURN rcm.id as rcm_id, rcm.titulo as rcm_title, a as avaliacao"
        )

        # --- Coleta de Dados de Prazos ---
        if status_callback:
            status_callback("Executando análise de prazos de entregas...")
        self.executar_ciclo_prazo_rcm()  # Executa e salva no grafo
        # Busca os resultados para o relatório
        avaliacoes_prazo_realizadas = self.graph.query(
            "MATCH (rcm:RCM)-[:AVALIADA_POR_PRAZO]->(a:AvaliacaoPrazo) RETURN rcm.id as rcm_id, rcm.titulo as rcm_titulo, a as avaliacao"
        )

        # --- Geração do Relatório Final ---
        if (
            not avaliacoes_conformidade_realizadas
            and not avaliacoes_entrega_realizadas
            and not avaliacoes_prazo_realizadas
        ):
            return "✅ Nenhuma nova RCM ou entrega encontrada para análise neste ciclo. Tudo em dia!"

        if status_callback:
            status_callback("Compilando relatório final...")
        return self._gerar_relatorio_gerencial(
            avaliacoes_conformidade_realizadas,
            avaliacoes_entrega_realizadas,
            avaliacoes_prazo_realizadas,
        )


if __name__ == "__main__":
    agente_qualidade = AgenteQualidade()
    agente_qualidade.executar_ciclo_validacao_entrega()

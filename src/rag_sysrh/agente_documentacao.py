import logging
import os
from typing import Any, Callable, Dict, List, Optional

from langchain_community.vectorstores import Neo4jVector
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import OpenAIEmbeddings
from pydantic import BaseModel, Field

from rag_sysrh.base_agent import BaseAgent

# Configura o logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


class PropostaAtualizacao(BaseModel):
    """
    Modelo de dados para uma proposta de atualização de documentação.
    """

    texto_atualizado: str = Field(
        description="O novo texto para o trecho da documentação, incorporando as mudanças da RCM."  # noqa: E501
    )
    resumo_da_mudanca: str = Field(
        description="Um resumo conciso explicando o que foi alterado na documentação."
    )


class AgenteDocumentacao(BaseAgent):
    """
    Agente autônomo para manter a documentação do sistema atualizada.
    """

    # Constantes de configuração
    _NEO4J_VECTOR_INDEX_NAME = "manual-chunks"

    def __init__(self) -> None:
        super().__init__()
        self.embeddings = OpenAIEmbeddings()
        # Inicializa o retriever para busca vetorial nos manuais
        self.retriever = Neo4jVector.from_existing_index(
            embedding=self.embeddings,  # Correção: Usa o modelo de embeddings
            url=os.getenv("NEO4J_URI"),
            username=os.getenv("NEO4J_USERNAME"),
            password=os.getenv("NEO4J_PASSWORD"),
            index_name=self._NEO4J_VECTOR_INDEX_NAME,
            text_node_property="texto",
        ).as_retriever(search_kwargs={"k": 10})

    def _buscar_rcms_para_documentar(self, limit: int = 5) -> list[dict]:
        """Busca RCMs concluídos que ainda não foram documentados."""
        logging.info("Buscando RCMs concluídos para documentar...")  # noqa: LOG015
        query = """
        MATCH (rcm:RCM)-[:ORIGINADO_DE]->(s:Solicitacao)
        WHERE toLower(rcm.status) IN ['concluído', 'entregue', 'aceite produção']
          AND (toLower(s.tipo_solicitacao) IN ['evolutivo', 'melhoria', 'corretivo'])
          AND NOT EXISTS((rcm)-[:GEROU_ATUALIZACAO]->(:AtualizacaoDocumento))
        RETURN
            rcm.id AS rcm_id,
            rcm.description AS rcm_texto,
            s.title AS solicitacao_titulo
        LIMIT $limit
        """
        return self.graph.query(query, params={"limit": limit})

    def _gerar_proposta_atualizacao(
        self, rcm_texto: str, texto_manual_original: str
    ) -> PropostaAtualizacao:
        """Usa um LLM para gerar uma nova versão do texto do manual."""
        structured_llm = self.llm.with_structured_output(PropostaAtualizacao)
        prompt = ChatPromptTemplate.from_template(
            """Você é um Escritor Técnico Sênior. Sua tarefa é atualizar um trecho de um manual de sistema com base em uma Requisição de Mudança (RCM) que foi implementada.

            **Trecho Original do Manual:**
            {manual_original}

            **Descrição da RCM (O que mudou):**
            {rcm}

            **Instruções:**
            1.  Leia a RCM para entender a mudança (seja uma correção de bug ou uma nova funcionalidade).
            2.  Re-escreva o "Trecho Original do Manual" para refletir com precisão a mudança descrita na RCM. Mantenha o tom e o estilo do texto original.
            3.  Crie um resumo claro e conciso da alteração que você fez.
            """  # noqa: E501
        )
        chain = prompt | structured_llm
        return chain.invoke(
            {"manual_original": texto_manual_original, "rcm": rcm_texto}
        )

    def _registrar_atualizacao(
        self, rcm_id: int, chunk_id: int, proposta: PropostaAtualizacao
    ) -> None:
        """Salva a proposta de atualização no grafo."""
        logging.info(  # noqa: LOG015
            f"Registrando atualização de documentação para o RCM ID {rcm_id}..."  # noqa: G004
        )

        # Gera um ID único para a atualização
        import uuid

        atualizacao_id = str(uuid.uuid4())

        query = """
        MATCH (rcm:RCM {id: $rcm_id})
        MATCH (chunk:Chunk) WHERE id(chunk) = $chunk_id
        CREATE (ad:AtualizacaoDocumento {
            id: $id,
            texto_atualizado: $texto_atualizado,
            resumo_da_mudanca: $resumo_da_mudanca,
            data_geracao: datetime(),
            status: 'Pendente'
        })
        MERGE (rcm)-[:GEROU_ATUALIZACAO]->(ad)
        MERGE (ad)-[:ATUALIZA_CHUNK]->(chunk)
        """
        self.graph.query(
            query,
            params={
                "id": atualizacao_id,
                "rcm_id": rcm_id,
                "chunk_id": chunk_id,
                "texto_atualizado": proposta.texto_atualizado,
                "resumo_da_mudanca": proposta.resumo_da_mudanca,
            },
        )

    def listar_atualizacoes_pendentes(self) -> List[Dict[str, Any]]:
        """Lista todas as atualizações de documentação pendentes de aprovação."""
        query = """
        MATCH (ad:AtualizacaoDocumento {status: 'Pendente'})
        MATCH (rcm:RCM)-[:GEROU_ATUALIZACAO]->(ad)
        RETURN 
            ad.id AS id,
            ad.resumo_da_mudanca AS resumo,
            ad.texto_atualizado AS texto_novo,
            rcm.titulo AS rcm_titulo,
            rcm.id AS rcm_id
        """
        return self.graph.query(query)

    def aprovar_atualizacao(self, atualizacao_id: str) -> bool:
        """Aprova uma atualização pendente."""
        logging.info(f"Aprovando atualização {atualizacao_id}...")
        query = """
        MATCH (ad:AtualizacaoDocumento {id: $id})
        SET ad.status = 'Aprovado', ad.data_aprovacao = datetime()
        RETURN ad.id
        """
        result = self.graph.query(query, params={"id": atualizacao_id})
        return len(result) > 0

    def _gerar_relatorio_documentacao(
        self, propostas_geradas: List[Dict[str, Any]]
    ) -> str:
        """Gera um relatório em Markdown sobre as propostas de atualização criadas."""
        logging.info("Gerando relatório do ciclo de documentação...")

        propostas_str = "\n".join(
            [
                f"- Proposta para RCM '{item['rcm_id']}' impactando {item['num_chunks']} trecho(s) de manual."
                for item in propostas_geradas
            ]
        )

        prompt = ChatPromptTemplate.from_template(
            """Você é um Gerente de Documentação Técnica. Sua tarefa é criar um relatório executivo em Markdown sobre as atividades do Agente de Documentação.

            **Resumo das Propostas de Atualização Geradas:**
            {propostas_str}

            **Instruções para o Relatório:**
            1.  **Título Principal:** Comece com `# Relatório do Ciclo de Documentação`.
            2.  **Resumo Executivo:** Escreva um parágrafo resumindo quantas RCMs foram analisadas e quantas propostas de atualização de documentação foram geradas.
            3.  **Detalhes das Propostas:**
                - Use o subtítulo `## 📑 Propostas Geradas`.
                - Liste cada proposta gerada, mencionando a RCM de origem e o número de documentos impactados.
            4.  **Próximos Passos:** Adicione uma seção `### ➡️ Próximos Passos` sugerindo que as propostas devem ser revisadas e aprovadas pela equipe técnica.

            Se nenhuma proposta foi gerada, apenas informe que nenhuma RCM nova necessitava de atualização na documentação.
            """
        )
        chain = prompt | self.llm | StrOutputParser()
        return chain.invoke({"propostas_str": propostas_str})

    def executar_ciclo_atualizacao(
        self,
        similaridade_minima: float = 0.8,
        status_callback: Optional[Callable[[str], None]] = None,
    ) -> str | None:
        """
        Executa o ciclo proativo de verificação de RCMs concluídas para propor
        atualizações na documentação.

        Args:
            similaridade_minima (float): Score mínimo de similaridade para considerar um chunk relevante.
            status_callback: Uma função opcional para receber atualizações de status.
        """
        if status_callback:
            status_callback("Iniciando ciclo de atualização...")
        logging.info("Iniciando ciclo de atualização proativa da documentação.")

        # Verifica se os dados necessários para as análises existem
        has_rcm_data = self.graph.query("MATCH (n:RCM) RETURN n LIMIT 1")
        if not has_rcm_data:
            return (
                "📄 Dados insuficientes para o Agente de Documentação! Para manter os manuais atualizados, o agente precisa acessar as RCMs implementadas.\n"  # noqa: E501
                "   - 📂 **Arquivo**: `rcms_01.csv`\n"
                "     **Descrição**: Contém os dados das Requisições de Mudança (RCMs) concluídas.\n"  # noqa: E501
                "     **Colunas essenciais**: `id`, `description` (com o detalhe da mudança), `status` e `id_solicitacao`."  # noqa: E501
            )

        if status_callback:
            status_callback("Buscando RCMs concluídas...")
        rcms_para_documentar = self._buscar_rcms_para_documentar()
        if not rcms_para_documentar:
            logging.info("Nenhuma nova RCM concluída para análise de documentação.")
            return "✅ Nenhuma RCM nova encontrada para documentar. A base de conhecimento está em dia!"

        if status_callback:
            status_callback(
                f"Analisando {len(rcms_para_documentar)} RCMs para impacto na documentação..."
            )
        logging.info(f"Encontradas {len(rcms_para_documentar)} RCMs para análise.")
        propostas_geradas = []
        for rcm in rcms_para_documentar:
            rcm_id = rcm["rcm_id"]
            rcm_texto = rcm.get("rcm_texto")

            if not rcm_texto:
                logging.warning(f"RCM {rcm_id} não possui descrição. Pulando análise.")
                continue

            try:
                # 1. Realizar busca vetorial por chunks similares
                # O retriever já faz a geração do embedding e a busca
                docs_relevantes = self.retriever.get_relevant_documents(
                    rcm_texto, score_threshold=similaridade_minima
                )

                if not docs_relevantes:
                    logging.info(
                        f"Nenhum chunk de documentação relevante encontrado para a RCM {rcm_id}."
                    )
                    continue

                logging.info(
                    f"RCM {rcm_id} impacta {len(docs_relevantes)} chunk(s). Gerando propostas de atualização."
                )

                # 2. Para cada chunk relevante, gerar e registrar uma proposta
                for doc in docs_relevantes:
                    texto_manual_original = doc.page_content
                    chunk_id = doc.metadata["id"]

                    # Gera a nova versão do texto e o resumo da mudança
                    proposta = self._gerar_proposta_atualizacao(
                        rcm_texto, texto_manual_original
                    )

                    # Salva a proposta no grafo
                    self._registrar_atualizacao(rcm_id, chunk_id, proposta)

                propostas_geradas.append(
                    {"rcm_id": rcm_id, "num_chunks": len(docs_relevantes)}
                )

            except Exception as e:
                logging.error(f"Falha ao processar a RCM {rcm_id}: {e}")

        if not propostas_geradas:
            return "✅ Análise concluída. Nenhuma proposta de atualização de documentação foi necessária neste ciclo."

        if status_callback:
            status_callback("Compilando relatório final...")
        logging.info("Ciclo de atualização proativa da documentação finalizado.")
        return self._gerar_relatorio_documentacao(propostas_geradas)

    def gerar_manual_por_topico(self, topico: str) -> str:
        """
        Busca informações sobre um tópico e gera um manual formatado em Markdown.
        """
        logging.info(f"Gerando manual para o tópico: {topico}")  # noqa: G004, LOG015

        # 1. Busca chunks de documentos relevantes usando busca vetorial
        docs_relevantes = self.retriever.invoke(topico)
        contexto = "\n\n---\n\n".join([doc.page_content for doc in docs_relevantes])

        # 2. Usa o LLM para compilar os chunks em um manual formatado
        prompt = ChatPromptTemplate.from_template(
            """Você é um Escritor Técnico e especialista em documentação de software.
            Sua tarefa é criar um manual de usuário claro e bem formatado sobre um tópico específico, usando os trechos de documentação fornecidos.

            **Tópico Solicitado:** {topico}

            **Trechos da Documentação:**
            {contexto}

            **Instruções:**
            1.  **Título:** Crie um título claro para o manual (ex: `# Manual de Usuário: Férias`).
            2.  **Introdução:** Escreva um parágrafo introdutório explicando o propósito do manual.
            3.  **Índice:** Crie um índice com links para as seções principais do documento.
            4.  **Conteúdo:** Organize os trechos fornecidos em seções lógicas e coerentes. Re-escreva e conecte as informações para que fluam como um documento único, não apenas uma lista de trechos. Use subtítulos (`##`, `###`) para cada seção.
            5.  **Formatação:** Use Markdown (negrito, listas, etc.) para melhorar a legibilidade.
            """  # noqa: E501
        )
        chain = prompt | self.llm | StrOutputParser()
        return chain.invoke({"topico": topico, "contexto": contexto})


if __name__ == "__main__":
    agente = AgenteDocumentacao()
    agente.executar_ciclo_atualizacao()

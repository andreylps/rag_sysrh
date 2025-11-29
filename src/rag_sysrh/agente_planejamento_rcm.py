import logging
import os
from typing import List, Optional

from docx import Document
from langchain_core.prompts import ChatPromptTemplate
from pydantic import BaseModel, Field

from rag_sysrh.analista_workflow import RelatorioAnalise
from rag_sysrh.base_agent import BaseAgent
from rag_sysrh.interfaces import ExternalConnector

# Configura o logging
logging.basicConfig(
    level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s"
)


class PlanoRCM(BaseModel):
    """Modelo de dados para um plano de RCM (Relatório de Controle de Mudança) estruturado."""

    titulo_rcm: str = Field(description="Título claro e conciso para a RCM.")
    objetivo_negocio: str = Field(
        description="Explicação do 'porquê' desta mudança e o valor que ela agrega ao negócio."
    )
    descricao_tecnica_detalhada: str = Field(
        description="Resumo técnico da solução proposta, herdado do diagnóstico."
    )
    plano_de_tarefas_sugerido: List[str] = Field(
        description="Plano de alto nível com as principais tarefas de desenvolvimento (ex: 'Alterar API', 'Ajustar interface', 'Criar testes')."
    )
    criterios_de_aceite: List[str] = Field(
        description="Lista de condições que devem ser verdadeiras para que a RCM seja considerada concluída."
    )
    riscos_mapeados: List[str] = Field(
        description="Possíveis riscos ou pontos de atenção identificados durante a análise."
    )
    estimativa_pontos_funcao: int = Field(
        description="Estimativa de esforço em Pontos de Função, herdada da análise."
    )
    prazo_dias_uteis: int = Field(
        description="Estimativa de prazo em dias úteis, herdada da análise."
    )


class AgentePlanejamentoRCM(BaseAgent):
    """
    Agente que transforma uma análise técnica em um plano de RCM estruturado.
    """

    def _carregar_modelo_rcm(self, caminho_arquivo: str) -> str:
        """Lê o conteúdo de um arquivo .docx para usar como modelo."""
        try:
            doc = Document(caminho_arquivo)
            full_text = [para.text for para in doc.paragraphs]
            return "\n".join(full_text)
        except Exception as e:
            logging.error(
                f"Erro ao carregar o modelo de RCM de '{caminho_arquivo}': {e}"
            )
            return "Nenhum modelo de layout pôde ser carregado."

    def gerar_plano_rcm(self, relatorio_analise: RelatorioAnalise) -> PlanoRCM:
        """
        Gera um plano de RCM estruturado com base no relatório de análise e em um modelo.
        """
        logging.info("Iniciando a geração do plano de RCM...")

        # Carrega o conteúdo do arquivo DOCX para usar como guia de layout
        # Constrói um caminho absoluto para o arquivo de modelo para robustez
        project_root = os.path.abspath(
            os.path.join(os.path.dirname(__file__), "..", "..")
        )
        modelo_path = os.path.join(
            project_root,
            "rcms",
            "SIGRH - RCM - Relatório de Controle de Mudança - CAD - 24328-2025.docx",
        )
        modelo_rcm_texto = self._carregar_modelo_rcm(modelo_path)

        # Obtém o ano atual para contexto
        from datetime import datetime

        ano_atual = datetime.now().year

        structured_llm = self.llm.with_structured_output(PlanoRCM)
        prompt = ChatPromptTemplate.from_template(
            """Você é um Gerente de Projetos Sênior. Sua tarefa é pegar um relatório de análise técnica e transformá-lo em um Relatório de Controle de Mudança (RCM) formal e bem estruturado.
            
            **CONTEXTO TEMPORAL:**
            - Estamos no ano de **{ano_atual}**. Todas as datas futuras devem considerar este ano.

            **1. DADOS DA ANÁLISE TÉCNICA (Sua fonte de informação):**
            - **Resumo do Problema:** {resumo_problema}
            - **Diagnóstico Técnico:** {diagnostico}
            - **Solução Sugerida:** {solucao_sugerida}
            - **Complexidade:** {complexidade}
            - **Estimativa (Pontos de Função):** {estimativa_pf}
            - **Prazo (Dias Úteis):** {prazo_dias}

            **2. MODELO DE LAYOUT E ESTRUTURA (Siga este formato):**
            --- INÍCIO DO MODELO ---
            {modelo_rcm}
            --- FIM DO MODELO ---

            **3. SUAS INSTRUÇÕES:**
            - Use os dados da **Análise Técnica** para preencher todas as informações do plano de RCM.
            - Use o **Modelo de Layout** como guia para a estrutura, seções e tom do documento.
            - Crie um `plano_de_tarefas_sugerido` que quebre a `solucao_sugerida` em passos lógicos.
            - Defina `criterios_de_aceite` claros e testáveis.
            - Herde as estimativas diretamente da análise.
            - Seja formal e profissional.
            - **CRÍTICO:** NÃO use tags HTML (como <p>, <div>, <br>, <style>). O texto deve ser **APENAS Markdown puro**. Se você gerar HTML, o sistema quebrará.
            """
        )

        chain = prompt | structured_llm
        plano = chain.invoke(
            {
                "resumo_problema": relatorio_analise.resumo_problema,
                "diagnostico": relatorio_analise.diagnostico,
                "solucao_sugerida": relatorio_analise.solucao_sugerida,
                "complexidade": relatorio_analise.complexidade,
                "estimativa_pf": relatorio_analise.detalhes_evolutiva.estimativa_pontos_funcao
                if relatorio_analise.detalhes_evolutiva
                else "N/A",
                "prazo_dias": relatorio_analise.detalhes_evolutiva.prazo_dias_uteis
                if relatorio_analise.detalhes_evolutiva
                else "N/A",
                "modelo_rcm": modelo_rcm_texto,
                "ano_atual": ano_atual,
            }
        )
        # Limpa HTML do plano gerado
        plano = self._limpar_html_plano(plano)

        logging.info("Plano de RCM gerado com sucesso.")
        return plano

    def _limpar_html_plano(self, plano: PlanoRCM) -> PlanoRCM:
        """Remove tags HTML dos campos de texto do plano."""
        import re

        def clean_text(text: str) -> str:
            if not text:
                return text
            # Remove tags HTML completas (com atributos)
            # Ex: <div style="...">, </p>, <br/>
            clean = re.sub(r"<[^>]+>", "", text)
            # Remove quebras de linha excessivas que podem ter sobrado
            clean = re.sub(r"\n\s*\n", "\n\n", clean)
            return clean.strip()

        # Limpa campos de texto simples
        plano.titulo_rcm = clean_text(plano.titulo_rcm)
        plano.objetivo_negocio = clean_text(plano.objetivo_negocio)
        plano.descricao_tecnica_detalhada = clean_text(
            plano.descricao_tecnica_detalhada
        )

        # Limpa campos de lista
        if plano.plano_de_tarefas_sugerido:
            plano.plano_de_tarefas_sugerido = [
                clean_text(item) for item in plano.plano_de_tarefas_sugerido
            ]

        if plano.criterios_de_aceite:
            plano.criterios_de_aceite = [
                clean_text(item) for item in plano.criterios_de_aceite
            ]

        if plano.riscos_mapeados:
            plano.riscos_mapeados = [clean_text(item) for item in plano.riscos_mapeados]

        return plano

    def salvar_plano_rcm(self, plano: PlanoRCM, solicitacao_id: int) -> str:
        """
        Salva o PlanoRCM gerado como um nó no Neo4j e o conecta à Solicitação original.
        Retorna o ID do nó criado.
        """
        logging.info(f"Salvando plano da RCM '{plano.titulo_rcm}' no grafo...")

        # Converte o objeto Pydantic em um dicionário para o Neo4j
        plano_props = plano.model_dump()

        # Define status inicial e ID se não tiver (embora o modelo não tenha ID, o nó precisa)
        import uuid

        plano_id = str(uuid.uuid4())
        plano_props["id"] = plano_id
        plano_props["status"] = "Pendente Aprovação"

        query = """
        // Cria um nó :PlanoRCM com as propriedades do plano e label de pendente
        CREATE (p:PlanoRCM:RCM_Pendente $plano_props)
        // Adiciona um timestamp de criação
        SET p.dataCriacao = datetime()
        
        // Tenta conectar o plano à solicitação que o originou (se existir)
        WITH p
        MATCH (s:Solicitacao {id: $solicitacao_id})
        MERGE (p)-[:PLANO_PARA]->(s)
        """

        self.graph.query(
            query,
            params={"solicitacao_id": solicitacao_id, "plano_props": plano_props},
        )
        logging.info(f"Plano de RCM salvo como Pendente Aprovação (ID: {plano_id}).")
        return plano_id

    def aprovar_plano_rcm(self, rcm_id: str) -> Optional[str]:
        """
        Aprova um PlanoRCM pendente, transformando-o em uma RCM oficial.
        Busca pelo ID do nó.
        """
        logging.info(f"Aprovando plano de RCM ID '{rcm_id}'...")

        query = """
        MATCH (p:PlanoRCM {id: $rcm_id})
        // Remove a label de pendente e adiciona a oficial
        REMOVE p:RCM_Pendente
        SET p:RCM
        SET p.status = 'Aberto'
        SET p.dataAprovacao = datetime()
        RETURN p.id as id
        """

        result = self.graph.query(query, params={"rcm_id": rcm_id})

        if result:
            rcm_id_aprovado = result[0]["id"]
            logging.info(
                f"RCM aprovada e oficializada com sucesso (ID: {rcm_id_aprovado})."
            )
            return rcm_id_aprovado
        else:
            logging.warning(
                f"Não foi possível aprovar a RCM ID '{rcm_id}'. Verifique se ela existe e está pendente."
            )
            return None

    def exportar_para_externo(
        self, rcm_id: str, connector: ExternalConnector
    ) -> Optional[str]:
        """
        Exporta uma RCM aprovada para um sistema externo usando o conector fornecido.
        """
        logging.info(f"Exportando RCM {rcm_id} para sistema externo...")

        # Busca os dados da RCM
        query = """
        MATCH (rcm:RCM {id: $id})
        RETURN rcm
        """
        result = self.graph.query(query, params={"id": rcm_id})

        if not result:
            logging.error(f"RCM {rcm_id} não encontrada para exportação.")
            return None

        rcm_node = result[0]["rcm"]
        # Converte o nó Neo4j para um dicionário Python puro
        rcm_data = dict(rcm_node)

        external_id = connector.create_issue(rcm_data)

        # Registra o ID externo no grafo
        update_query = """
        MATCH (rcm:RCM {id: $id})
        SET rcm.external_id = $ext_id, rcm.exported_at = datetime()
        """
        self.graph.query(update_query, params={"id": rcm_id, "ext_id": external_id})

        logging.info(f"RCM {rcm_id} exportada com sucesso. ID Externo: {external_id}")
        return external_id

    def formatar_plano_para_markdown(self, plano: PlanoRCM) -> str:
        """Formata o objeto PlanoRCM em uma string Markdown com layout profissional."""
        # Pré-formata as listas para evitar sequências de escape dentro da f-string principal
        tarefas_md = "\n".join(
            [f"- [ ] {tarefa}" for tarefa in plano.plano_de_tarefas_sugerido]
        )
        criterios_md = "\n".join(
            [f"- {criterio}" for criterio in plano.criterios_de_aceite]
        )
        riscos_md = (
            "\n".join([f"- {risco}" for risco in plano.riscos_mapeados])
            if plano.riscos_mapeados
            else "Nenhum risco significativo mapeado."
        )

        markdown_output = f"""
### 📄 **Relatório de Controle de Mudança (RCM)**

---

#### **Título:** {plano.titulo_rcm}

**Objetivo de Negócio:**
> {plano.objetivo_negocio}

---

#### **Análise Técnica e Solução Proposta**
**Descrição Técnica Detalhada:**
<p style="text-align: justify;">{plano.descricao_tecnica_detalhada}</p>

---

#### **Plano de Execução e Critérios de Aceite**

**Plano de Tarefas Sugerido:**
{tarefas_md}

**Critérios de Aceite:**
{criterios_md}

---

#### **Riscos e Estimativas**

**Riscos Mapeados:**
{riscos_md}

---
**Estimativas:**
| Pontos de Função | Prazo em Dias Úteis |
|:---:|:---:|
| {plano.estimativa_pontos_funcao} PF | {plano.prazo_dias_uteis} dias |

"""
        return markdown_output

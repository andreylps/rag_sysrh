import datetime
import logging
import os
from pathlib import Path
from typing import Any

from docx import Document
from dotenv import load_dotenv
from langchain_neo4j import Neo4jGraph

from rag_sysrh.engine.models import ResultadoSISP

load_dotenv()


logger = logging.getLogger(__name__)


class DocumentGenerator:
    """
    Gerador de documentação formal (Excel e Word) para o processo SISP.
    """

    def __init__(self, templates_dir: str = "data/Layout"):
        self.templates_dir = Path(templates_dir)
        # Prioritize modern formats with macros/formulas
        self.excel_template = (
            self._find_template(".xlsm")
            or self._find_template(".xlsx")
            or self._find_template(".xls")
        )
        self.word_template = self._find_template(".docx")

    def _find_template(self, ext: str) -> Path | None:
        """Encontra o primeiro arquivo com a extensão dada no diretório de templates."""
        if not self.templates_dir.exists():
            return None
        for file in self.templates_dir.iterdir():
            if file.suffix.lower() == ext and (
                "MODELO" in file.name.upper() or "MOD" in file.name.upper()
            ):
                return file
        return None

    def generate_documents(
        self, resultado: ResultadoSISP, rcm_id: str
    ) -> ResultadoSISP:
        """
        Gera ambos os documentos e atualiza o objeto de resultado com os caminhos.
        """
        output_dir = Path("data/resultado_analise") / rcm_id
        output_dir.mkdir(parents=True, exist_ok=True)

        # 1. Gerar Excel (Memória de Cálculo)
        if self.excel_template:
            # Verifica extensão. Se for .xls, openpyxl não abre.
            # O ideal seria converter, mas aqui vamos assumir que se o usuário pediu openpyxl,
            # ele fornecerá um .xlsx ou aceitará que o sistema tente abrir.
            # Se for .xls real, vai falhar. Vamos tentar tratar.
            # Define a extensão de saída baseada no template
            ext = ".xlsm" if self.excel_template.suffix.lower() == ".xlsm" else ".xlsx"
            excel_path = output_dir / f"Memoria_Calculo_{rcm_id}{ext}"

            if self.excel_template.suffix.lower() == ".xls":
                logger.warning(
                    "Template é .xls. OpenPyXL não suporta escrita em .xls nativo. Tentando abrir como .xlsx renomeado ou falhará."
                )
                # Em produção, usaríamos uma lib de conversão ou pediríamos .xlsx.
                # Aqui, vamos tentar copiar e abrir. Se falhar, o usuário deve fornecer .xlsx.

            try:
                self._generate_excel(self.excel_template, excel_path, resultado, rcm_id)
                resultado.memoria_calculo_path = str(excel_path)
            except Exception as e:
                logger.error(f"Erro ao gerar Excel: {e}")
                resultado.memoria_calculo_path = f"ERRO: {e}"
        else:
            logger.warning("Template Excel não encontrado.")

        # 2. Gerar Word (RCM)
        if self.word_template:
            word_path = output_dir / f"RCM_{rcm_id}.docx"
            try:
                self._generate_word(self.word_template, word_path, resultado, rcm_id)
                resultado.rcm_path = str(word_path)
            except Exception as e:
                logger.error(f"Erro ao gerar Word: {e}")
                resultado.rcm_path = f"ERRO: {e}"
        else:
            logger.warning("Template Word não encontrado.")

        return resultado

    def gerar_memoria_calculo(self, resultado: ResultadoSISP, rcm_id: str) -> Path:
        """Gera a memória de cálculo e retorna o caminho."""
        output_dir = Path("data/resultado_analise") / rcm_id
        output_dir.mkdir(parents=True, exist_ok=True)

        ext = ".xlsx"
        if self.excel_template and self.excel_template.suffix.lower() == ".xlsm":
            ext = ".xlsm"
        excel_path = output_dir / f"Memoria_Calculo_{rcm_id}{ext}"

        if self.excel_template:
            try:
                self._generate_excel(self.excel_template, excel_path, resultado, rcm_id)
                return excel_path
            except Exception as e:
                logger.error(f"Erro ao gerar Excel: {e}")
                return Path("ERRO_GERACAO_EXCEL")
        return Path("TEMPLATE_NAO_ENCONTRADO")

    def _get_next_rcm_id(self) -> tuple[int, int]:
        """
        Consulta o Neo4j para obter o próximo número sequencial de RCM para o ano atual.
        Retorna uma tupla (sequencial, ano).
        """
        try:
            graph = Neo4jGraph(
                url=os.getenv("NEO4J_URI"),
                username=os.getenv("NEO4J_USERNAME"),
                password=os.getenv("NEO4J_PASSWORD"),
            )
            now = datetime.datetime.now()
            ano_atual = now.year

            # Busca o maior ID de RCM do ano atual
            # Assumindo que o ID no banco é salvo como string "XXXX/YYYY" ou similar,
            # ou que existe uma propriedade 'sequencial' e 'ano'.
            # Vamos buscar por padrão de string se não houver propriedades separadas.
            # Mas para garantir, vamos tentar buscar o nó com maior sequencial.

            query = """
            MATCH (r:RCM)
            WHERE r.ano = $ano
            RETURN max(r.sequencial) as max_seq
            """
            result = graph.query(query, params={"ano": ano_atual})

            max_seq = 0
            if result and result[0]["max_seq"] is not None:
                max_seq = result[0]["max_seq"]

            next_seq = max_seq + 1
            return next_seq, ano_atual

        except Exception as e:
            logger.error(f"Erro ao obter próximo ID de RCM: {e}")
            # Fallback para evitar falha total, mas idealmente não deveria acontecer
            return 9999, datetime.datetime.now().year

    def gerar_rcm(
        self,
        solicitacao: str,
        diagnostico: str,
        resultado: ResultadoSISP,
        risco: Any = None,
    ) -> Path:
        """Gera a RCM e retorna o caminho."""

        # 1. Obtém o próximo ID sequencial
        seq, ano = self._get_next_rcm_id()
        rcm_id_formatted = f"{seq:04d}/{ano}"

        # Título da RCM (Pode ser extraído da solicitação ou passado como argumento)
        # Vamos tentar extrair um título curto ou usar um genérico
        titulo_rcm = "ALTERAÇÃO NO SISTEMA"  # Default
        if resultado.itens_calculados:
            # Usa o nome da primeira função como base ou algo similar
            titulo_rcm = f"ALTERAÇÃO - {resultado.itens_calculados[0].nome.upper()}"

        # Nome do arquivo: XXXX/ANO - TÍTULO.docx
        # Windows não aceita '/' em nome de arquivo. Vamos usar '-' ou '_'.
        # O user pediu "XXXX/ANO - ...", mas isso é caminho de pasta ou nome de arquivo?
        # Se for nome de arquivo, '/' é proibido. Vou usar '-' no lugar da barra para o arquivo físico.
        filename = f"{seq:04d}_{ano} - {titulo_rcm}.docx"

        # Cria diretório se não existir
        output_dir = Path("data/resultado_analise") / f"{seq:04d}_{ano}"
        output_dir.mkdir(parents=True, exist_ok=True)

        word_path = output_dir / filename

        if self.word_template:
            try:
                self._generate_word(
                    self.word_template,
                    word_path,
                    resultado,
                    rcm_id_formatted,
                    solicitacao,
                    diagnostico,
                    risco,
                    titulo_rcm,
                )
                return word_path
            except Exception as e:
                logger.error(f"Erro ao gerar Word: {e}")
                return Path("ERRO_GERACAO_WORD")
        return Path("TEMPLATE_NAO_ENCONTRADO")

    def _generate_word(
        self,
        template_path: Path,
        output_path: Path,
        resultado: ResultadoSISP,
        rcm_id: str,
        solicitacao: str = "",
        diagnostico: str = "",
        risco: Any = None,
        titulo_rcm: str = "",
    ):
        """Preenche o documento Word."""
        doc = Document(template_path)

        now = datetime.datetime.now()
        mes_ano = now.strftime("%m/%Y")

        # Formata a análise de risco se existir
        analise_risco_str = "N/A"
        if risco:
            analise_risco_str = (
                f"Impacto Backend: {risco.impacto_backend}/5\n"
                f"Impacto Frontend: {risco.impacto_frontend}/5\n"
                f"Risco Migração: {risco.risco_migracao}/5\n"
                f"Esforço Testes: {risco.esforco_testes}/5\n"
                f"Incerteza: {risco.incerteza_requisitos}/5\n"
                f"Justificativa: {risco.justificativa_geral}"
            )

        replacements = {
            "<RCM>": rcm_id,
            "<PF_TOTAL>": f"{resultado.pf_liquido_total:.2f}",
            "<PRAZO_DIAS>": str(resultado.prazo_estimado_dias),
            "<DATA>": mes_ano,
            "<HEADER_RCM>": f"RCM {rcm_id}",
            "<TITULO_MODULO>": titulo_rcm,
            "<SOLICITACAO>": solicitacao,
            "<DIAGNOSTICO>": diagnostico,
            "<SOLUCAO>": diagnostico,  # Muitas vezes diagnóstico e solução se misturam, ou podemos separar se tivermos o campo
            "<ANALISE_RISCO>": analise_risco_str,
            "<RISCO>": analise_risco_str,  # Alias
        }

        # Substituição em parágrafos
        for para in doc.paragraphs:
            for key, val in replacements.items():
                if key in para.text:
                    para.text = para.text.replace(key, str(val))

        # Substituição em tabelas
        for table in doc.tables:
            for row in table.rows:
                for cell in row.cells:
                    for para in cell.paragraphs:
                        for key, val in replacements.items():
                            if key in para.text:
                                para.text = para.text.replace(key, str(val))

        # Inserir Tabela na seção "Estimativa de Esforço"
        # (Mantém lógica anterior de adicionar tabela no final)
        doc.add_heading(
            "Detalhamento da Estimativa de Esforço (Memória de Cálculo)", level=2
        )

        table = doc.add_table(rows=1, cols=10)
        table.style = "Table Grid"
        hdr_cells = table.rows[0].cells
        headers = [
            "Casos de Uso",
            "Função",
            "Tipo",
            "I/A/E",
            "TD",
            "AR",
            "Comp",
            "PF",
            "PF Liq",
            "Obs",
        ]
        for i, h in enumerate(headers):
            hdr_cells[i].text = h

        deflator = resultado.pf_liquido_total / (resultado.pf_bruto_total or 1)

        for item in resultado.itens_calculados:
            row_cells = table.add_row().cells
            row_cells[0].text = str(item.descricao)
            row_cells[1].text = str(item.nome)
            row_cells[2].text = str(item.tipo.value)
            row_cells[3].text = "I"
            row_cells[4].text = str(item.der_estimado)
            row_cells[5].text = str(item.rlr_estimado)
            row_cells[6].text = str(
                item.complexidade.value if item.complexidade else ""
            )
            row_cells[7].text = f"{item.pf_bruto:.2f}"
            row_cells[8].text = f"{item.pf_bruto * deflator:.2f}"
            row_cells[9].text = str(item.justificativa_contagem)

        doc.save(output_path)

    def _generate_excel(
        self,
        template_path: Path,
        output_path: Path,
        resultado: ResultadoSISP,
        rcm_id: str,
    ):
        """Preenche o documento Excel."""
        import openpyxl

        wb = openpyxl.load_workbook(template_path)
        ws = wb.active

        # Substituição simples em células
        replacements = {
            "<RCM>": rcm_id,
            "<PF_TOTAL>": f"{resultado.pf_liquido_total:.2f}",
            "<PRAZO_DIAS>": str(resultado.prazo_estimado_dias),
        }

        for row in ws.iter_rows():
            for cell in row:
                if cell.value and isinstance(cell.value, str):
                    for key, val in replacements.items():
                        if key in cell.value:
                            cell.value = cell.value.replace(key, str(val))

        # Adiciona ou usa aba de detalhamento
        if "Detalhamento" in wb.sheetnames:
            ws_det = wb["Detalhamento"]
            # Limpa dados existentes se for template reutilizado (opcional, aqui apenas append)
        else:
            ws_det = wb.create_sheet("Detalhamento")
            ws_det.append(
                [
                    "Função",
                    "Tipo",
                    "DER",
                    "RLR",
                    "Complexidade",
                    "PF Bruto",
                    "PF Líquido",
                ]
            )

        deflator = resultado.pf_liquido_total / (resultado.pf_bruto_total or 1)

        for item in resultado.itens_calculados:
            ws_det.append(
                [
                    item.nome,
                    item.tipo.value,
                    item.der_estimado,
                    item.rlr_estimado,
                    item.complexidade.value if item.complexidade else "",
                    item.pf_bruto,
                    item.pf_bruto * deflator,
                ]
            )

        wb.save(output_path)

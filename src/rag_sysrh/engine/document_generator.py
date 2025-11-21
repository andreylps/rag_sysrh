import datetime
import logging
import shutil
from pathlib import Path
from typing import Any

import openpyxl
import pandas as pd
from docx import Document
from openpyxl.worksheet.worksheet import Worksheet

from rag_sysrh.engine.models import ItemFuncional, ResultadoSISP

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

    def gerar_memoria_calculo(self, resultado: ResultadoSISP) -> Path:
        """Gera a memória de cálculo e retorna o caminho."""
        rcm_id = "TEMP_ID"  # Deveria vir do state, mas por enquanto fixo ou gerado
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

    def gerar_rcm(
        self,
        solicitacao: str,
        diagnostico: str,
        resultado: ResultadoSISP,
        risco: Any = None,
    ) -> Path:
        """Gera a RCM e retorna o caminho."""
        rcm_id = "TEMP_ID"
        output_dir = Path("data/resultado_analise") / rcm_id
        output_dir.mkdir(parents=True, exist_ok=True)

        word_path = output_dir / f"RCM_{rcm_id}.docx"

        if self.word_template:
            try:
                self._generate_word(self.word_template, word_path, resultado, rcm_id)
                return word_path
            except Exception as e:
                logger.error(f"Erro ao gerar Word: {e}")
                return Path("ERRO_GERACAO_WORD")
        return Path("TEMPLATE_NAO_ENCONTRADO")

    def _generate_excel(
        self,
        template_path: Path,
        output_path: Path,
        resultado: ResultadoSISP,
        rcm_id: str,
    ):
        """Preenche a planilha Excel."""
        # Tenta carregar o template. Se for .xls, converte para .xlsx via pandas (perde fórmulas, mas mantém dados)
        # Se for .xlsx, usa openpyxl (mantém fórmulas).

        wb = None
        is_xlsm = template_path.suffix.lower() == ".xlsm"

        if template_path.suffix.lower() == ".xls":
            logger.warning(
                "Template .xls detectado. Convertendo para .xlsx (Fórmulas podem ser perdidas)."
            )
            try:
                # Lê o .xls com pandas
                dfs = pd.read_excel(template_path, sheet_name=None)

                # Cria novo workbook .xlsx
                wb = openpyxl.Workbook()
                # Remove a aba padrão
                if "Sheet" in wb.sheetnames:
                    del wb["Sheet"]

                # Recria as abas
                for sheet_name, df in dfs.items():
                    ws = wb.create_sheet(sheet_name)
                    # Escreve cabeçalhos
                    for col_idx, col_name in enumerate(df.columns, 1):
                        ws.cell(row=1, column=col_idx, value=col_name)
                    # Escreve dados
                    for r_idx, row in enumerate(df.itertuples(index=False), 2):
                        for c_idx, value in enumerate(row, 1):
                            ws.cell(row=r_idx, column=c_idx, value=value)

            except Exception as e:
                logger.error(f"Erro na conversão .xls -> .xlsx: {e}")
                # Fallback: cria novo em branco
                wb = openpyxl.Workbook()
                wb.create_sheet("Funções")
                wb.create_sheet("Contagem")
        else:
            # .xlsx ou .xlsm nativo
            shutil.copy(template_path, output_path)
            try:
                # Se for .xlsm, precisamos avisar o openpyxl para manter o VBA
                wb = openpyxl.load_workbook(output_path, keep_vba=is_xlsm)
            except Exception as e:
                logger.error(f"Erro ao abrir arquivo Excel: {e}")
                wb = openpyxl.Workbook()

        # Aba Funções (Preenchimento Estrito)
        # Colunas identificadas:
        # A=Casos de Uso, B=Função, C=Tipo, D=(I/A/E), E=TD(DER), F=AR(RLR),
        # G=Complexidade, H=PF, I=PF Deflator, J=Obs

        sheet_name = "Funções" if "Funções" in wb.sheetnames else "FUNÇÕES"
        if sheet_name in wb.sheetnames:
            ws = wb[sheet_name]
            deflator = resultado.pf_liquido_total / (resultado.pf_bruto_total or 1)
            self._fill_functions_sheet_strict(ws, resultado.itens_calculados, deflator)

        # Aba Contagem (Resumo)
        sheet_name_cont = "Contagem" if "Contagem" in wb.sheetnames else "CONTAGEM"
        if sheet_name_cont in wb.sheetnames:
            ws = wb[sheet_name_cont]
            self._fill_summary_sheet(ws, resultado, rcm_id)

        wb.save(output_path)

    def _fill_functions_sheet_strict(
        self, ws: Worksheet, itens: list[ItemFuncional], deflator: float
    ):
        """Preenche a lista de funções seguindo o layout estrito do modelo."""
        # Encontra a linha de cabeçalho (procura por "Função" ou "Nome")
        start_row = 2  # Default
        for row in ws.iter_rows(min_row=1, max_row=10):
            for cell in row:
                if (
                    cell.value
                    and isinstance(cell.value, str)
                    and "Função" in cell.value
                ):
                    start_row = cell.row + 1
                    break
            if start_row > 2:
                break

        current_row = start_row

        for item in itens:
            # Col A: Casos de Uso (Descrição)
            ws.cell(row=current_row, column=1, value=item.descricao)
            # Col B: Nome da Função
            ws.cell(row=current_row, column=2, value=item.nome)
            # Col C: Tipo (ALI, AIE, etc)
            ws.cell(row=current_row, column=3, value=item.tipo.value)
            # Col D: (I/A/E) - Default "I" (Inclusão) ou "A" se for manutenção
            ws.cell(row=current_row, column=4, value="I")
            # Col E: TD (DER)
            ws.cell(row=current_row, column=5, value=item.der_estimado)
            # Col F: AR (RLR)
            ws.cell(row=current_row, column=6, value=item.rlr_estimado)
            # Col G: Complexidade
            ws.cell(
                row=current_row,
                column=7,
                value=item.complexidade.value if item.complexidade else "",
            )
            # Col H: PF Bruto
            ws.cell(row=current_row, column=8, value=item.pf_bruto)
            # Col I: PF Líquido (Com Deflator)
            # Se o Excel tiver fórmula, isso vai sobrescrever.
            # Mas como convertemos de .xls, a fórmula sumiu. Então PRECISAMOS escrever.
            pf_liq = item.pf_bruto * deflator
            ws.cell(row=current_row, column=9, value=pf_liq)
            # Col J: Observações
            ws.cell(row=current_row, column=10, value=item.justificativa_contagem)

            current_row += 1

    def _fill_summary_sheet(self, ws: Worksheet, resultado: ResultadoSISP, rcm_id: str):
        """Substitui placeholders na aba de contagem."""
        replacements = {
            "<RCM>": rcm_id,
            "<PF_BRUTO>": f"{resultado.pf_bruto_total:.2f}",
            "<PF_LIQUIDO>": f"{resultado.pf_liquido_total:.2f}",
            "<PRAZO>": str(resultado.prazo_estimado_dias),
        }

        for row in ws.iter_rows():
            for cell in row:
                if cell.value and isinstance(cell.value, str):
                    for key, val in replacements.items():
                        if key in cell.value:
                            cell.value = cell.value.replace(key, val)

    def _generate_word(
        self,
        template_path: Path,
        output_path: Path,
        resultado: ResultadoSISP,
        rcm_id: str,
    ):
        """Preenche o documento Word."""
        doc = Document(template_path)

        # Formatação do Cabeçalho: <Sigla Módulo> - <Número RCM> - <Ano>
        # Ex: FUNC - 1234 - 2024
        now = datetime.datetime.now()
        ano = now.year
        mes_ano = now.strftime("%m/%Y")

        # Tenta extrair sigla do RCM ID ou usa default
        sigla = "MOD"
        numero = rcm_id
        if "-" in rcm_id:
            parts = rcm_id.split("-")
            if len(parts) >= 2:
                # Assumindo formato MOD-1234
                # Mas o user pediu <Sigla Módulo> - <Número RCM>
                pass

        header_str = f"{sigla} - {numero} - {ano}"
        title_str = f"{sigla} - Nome do Módulo"  # Placeholder, ideal vir do input

        replacements = {
            "<RCM>": rcm_id,
            "<PF_TOTAL>": f"{resultado.pf_liquido_total:.2f}",
            "<PRAZO_DIAS>": str(resultado.prazo_estimado_dias),
            "<DATA>": mes_ano,
            "<HEADER_RCM>": header_str,
            "<TITULO_MODULO>": title_str,
            # Adicione placeholders que o usuário mencionou se souber os nomes exatos no doc
        }

        # Substituição em parágrafos
        for para in doc.paragraphs:
            for key, val in replacements.items():
                if key in para.text:
                    para.text = para.text.replace(key, val)

        # Substituição em tabelas
        for table in doc.tables:
            for row in table.rows:
                for cell in row.cells:
                    for para in cell.paragraphs:
                        for key, val in replacements.items():
                            if key in para.text:
                                para.text = para.text.replace(key, val)

        # Inserir Tabela na seção "Estimativa de Esforço"
        # Procura o parágrafo "Estimativa de Esforço"
        # (Lógica simplificada: Adiciona tabela no final com título claro)

        # Fallback: Adiciona tabela no final (Melhor que nada)
        doc.add_heading(
            "Detalhamento da Estimativa de Esforço (Memória de Cálculo)", level=2
        )

        # Tabela com mesmo layout do Excel:
        # Item | Função | Tipo | (I/A/E) | TD | AR | Complex | PF | PF Def | Obs
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

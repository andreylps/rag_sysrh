import logging
import os
from pathlib import Path
from typing import List, Optional

from pydantic import BaseModel

from rag_sysrh.engine.document_generator import DocumentGenerator
from rag_sysrh.engine.models import ItemFuncional, TipoFuncao
from rag_sysrh.engine.sisp_calculator import SISPCalculator

logger = logging.getLogger(__name__)


class DocumentGenerationRequest(BaseModel):
    titulo: str
    descricao: str
    itens: List[dict]  # Lista de itens funcionais simplificados
    deflator: float = 0.5


class DocumentGenerationResponse(BaseModel):
    rcm_filename: Optional[str] = None
    memoria_filename: Optional[str] = None
    message: str


class DocumentService:
    def __init__(self):
        self.calculator = SISPCalculator()
        # Assumindo que o diretório de templates está na raiz do projeto ou configurado
        # Ajuste o caminho conforme necessário. O DocumentGenerator usa "data/Layout" por padrão.
        self.generator = DocumentGenerator()

    def generate_documents(
        self, request: DocumentGenerationRequest
    ) -> DocumentGenerationResponse:
        try:
            # 1. Converter itens do request para ItemFuncional
            itens_funcionais = []
            for item in request.itens:
                itens_funcionais.append(
                    ItemFuncional(
                        nome=item.get("nome", "Item Sem Nome"),
                        tipo=TipoFuncao(item.get("tipo", "ALI")),
                        descricao=item.get("descricao", ""),
                        der_estimado=int(item.get("der", 0)),
                        rlr_estimado=int(item.get("rlr", 0)),
                        justificativa_contagem=item.get(
                            "justificativa", "Gerado via API"
                        ),
                    )
                )

            # 2. Calcular Métricas SISP
            resultado_sisp = self.calculator.calcular_pf(
                itens_funcionais, request.deflator
            )

            # 3. Gerar Documentos
            # Gera um ID temporário ou usa um sequencial
            # O DocumentGenerator busca o próximo ID do Neo4j, então podemos passar um dummy aqui
            # mas ele usa esse ID para criar a pasta.
            # Vamos deixar o gerador decidir o ID interno, mas precisamos passar algo.
            # O método gerar_rcm do generator já busca o ID sequencial.

            # Gerar RCM (Word)
            rcm_path = self.generator.gerar_rcm(
                solicitacao=request.titulo,
                diagnostico=request.descricao,
                resultado=resultado_sisp,
            )

            # Gerar Memória de Cálculo (Excel)
            # O gerador de memória precisa do ID. Vamos extrair do nome do arquivo RCM gerado ou gerar um novo.
            # O ideal seria refatorar o generator para ser mais coeso, mas vamos adaptar.
            # O gerar_rcm retorna o Path completo. Ex: data/resultado_analise/0001_2025/0001_2025 - Titulo.docx

            if str(rcm_path).startswith("ERRO") or str(rcm_path).startswith("TEMPLATE"):
                return DocumentGenerationResponse(
                    message=f"Erro na geração do RCM: {rcm_path}"
                )

            # Extrai o ID da pasta criada (parent)
            rcm_id_folder = rcm_path.parent.name  # Ex: 0001_2025

            memoria_path = self.generator.gerar_memoria_calculo(
                resultado_sisp, rcm_id_folder
            )

            return DocumentGenerationResponse(
                rcm_filename=str(rcm_path),  # Retorna o caminho relativo ou absoluto
                memoria_filename=str(memoria_path),
                message="Documentos gerados com sucesso.",
            )

        except Exception as e:
            logger.error(f"Erro no serviço de geração de documentos: {e}")
            return DocumentGenerationResponse(message=f"Erro interno: {str(e)}")

    def get_file_path(self, filename: str) -> Path:
        """
        Valida e retorna o caminho absoluto do arquivo solicitado para download.
        Segurança: Impede Path Traversal.
        """
        # O filename recebido pode ser um caminho relativo vindo do response anterior
        # Ex: data/resultado_analise/0001_2025/arquivo.docx

        base_path = Path(os.getcwd())
        file_path = base_path / filename

        # Resolve para caminho absoluto
        file_path = file_path.resolve()

        # Verifica se o arquivo está dentro do diretório do projeto (segurança básica)
        if not str(file_path).startswith(str(base_path)):
            raise ValueError("Acesso negado: Arquivo fora do diretório permitido.")

        if not file_path.exists():
            raise FileNotFoundError("Arquivo não encontrado.")

        return file_path

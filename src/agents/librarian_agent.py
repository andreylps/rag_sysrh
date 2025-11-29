import logging
import os
from datetime import datetime
from typing import Dict, List

from langchain_community.document_loaders import (
    Docx2txtLoader,
    PyPDFLoader,
    TextLoader,
    UnstructuredExcelLoader,
)
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_openai import ChatOpenAI

# Configuração de Logging
logger = logging.getLogger(__name__)

# Diretórios monitorados (Apenas subdiretórios de 'data')
DATA_ROOT = "data"

# Extensões suportadas e seus loaders
LOADERS = {
    ".txt": TextLoader,
    ".md": TextLoader,
    ".docx": Docx2txtLoader,
    ".xlsx": UnstructuredExcelLoader,
    ".pdf": PyPDFLoader,
}


class LibrarianAgent:
    def __init__(self):
        self.llm = ChatOpenAI(model="gpt-4o", temperature=0)
        self.system_prompt = """
        Você é o Agente Bibliotecário do sistema RAG_SYSRH.
        Sua missão é organizar, resumir e facilitar o acesso à documentação do projeto.
        
        Você é especialista em:
        1. Manuais Operacionais (Instruções de uso e manutenção).
        2. RCMs (Relatórios de Mudança e Requisitos).
        3. Memórias de Cálculo (Planilhas de Ponto de Função SISP).
        4. Guias de Métricas (Documentação oficial SISP/ISO).
        
        Ao resumir, seja conciso, destaque o objetivo do documento, principais funcionalidades ou mudanças, e qualquer ponto de atenção.
        """

    def list_documents(self, subdirectory: str = "") -> List[Dict]:
        """Lista conteúdos (arquivos e pastas) de um subdiretório de 'data'."""
        items = []
        base_path = os.getcwd()

        # Security: Prevent directory traversal
        safe_sub = subdirectory.strip("/\\")
        if ".." in safe_sub:
            logger.warning(
                f"LibrarianAgent: Attempted directory traversal: {subdirectory}"
            )
            return []

        target_path = os.path.join(base_path, DATA_ROOT, safe_sub)
        logger.info(f"LibrarianAgent: Listing contents of {target_path}")

        if not os.path.exists(target_path):
            logger.warning(f"LibrarianAgent: Path not found: {target_path}")
            return []

        # Itera sobre os itens no diretório alvo
        for item in os.listdir(target_path):
            item_path = os.path.join(target_path, item)
            relative_path = os.path.relpath(item_path, base_path)
            stats = os.stat(item_path)
            last_modified = datetime.fromtimestamp(stats.st_mtime).isoformat()

            if os.path.isdir(item_path):
                items.append(
                    {
                        "name": item,
                        "path": item_path,
                        "relative_path": relative_path,
                        "type": "folder",
                        "size": 0,
                        "last_modified": last_modified,
                    }
                )
            else:
                ext = os.path.splitext(item)[1].lower()
                if ext in LOADERS:
                    doc_type = self._infer_doc_type(item_path)
                    items.append(
                        {
                            "name": item,
                            "path": item_path,
                            "relative_path": relative_path,
                            "type": doc_type,
                            "size": stats.st_size,
                            "last_modified": last_modified,
                        }
                    )

        # Sort: Folders first, then files
        items.sort(key=lambda x: (x["type"] != "folder", x["name"].lower()))
        return items

    def _infer_doc_type(self, file_path: str) -> str:
        """Infere o tipo de documento baseado no caminho."""
        path_lower = file_path.lower()
        if "generated_rcm" in path_lower:
            return "RCM"
        elif "generated_memcalc" in path_lower:
            return "Memória de Cálculo"
        elif "generated_manuals" in path_lower or "manuais" in path_lower:
            return "Manual Operacional"
        elif "guia_metricas" in path_lower:
            return "Guia SISP"
        return "Outros"

    async def summarize_document(self, file_path: str) -> str:
        """Gera um resumo do documento usando LLM."""
        try:
            ext = os.path.splitext(file_path)[1].lower()
            loader_cls = LOADERS.get(ext)

            if not loader_cls:
                return "Tipo de arquivo não suportado para resumo."

            loader = loader_cls(file_path)
            docs = loader.load()

            if not docs:
                return "Documento vazio ou ilegível."

            # Concatena o conteúdo (limitando para não estourar contexto se for gigante)
            content = "\n\n".join([d.page_content for d in docs])
            content = content[:20000]  # Limite de segurança de caracteres

            prompt = ChatPromptTemplate.from_messages(
                [
                    ("system", self.system_prompt),
                    (
                        "user",
                        "Gere um resumo executivo do seguinte documento:\n\n{content}",
                    ),
                ]
            )

            chain = prompt | self.llm | StrOutputParser()
            summary = await chain.ainvoke({"content": content})

            return summary

        except Exception as e:
            logger.error(f"Erro ao resumir documento {file_path}: {e}")
            return f"Erro ao gerar resumo: {str(e)}"

    async def search_documents(self, query: str) -> List[Dict]:
        """
        Busca documentos relevantes.
        Por enquanto, implementa uma busca híbrida: Filtro por nome + Busca semântica simplificada (se possível).
        """
        all_docs = self.list_documents()
        results = []

        # 1. Busca simples por nome (Keyword match)
        query_lower = query.lower()
        for doc in all_docs:
            if query_lower in doc["name"].lower() or query_lower in doc["type"].lower():
                results.append(doc)

        # TODO: Implementar busca vetorial completa (VectorStore) em fase futura
        # Para MVP, a busca por nome/tipo já atende a navegação básica.

        return results


# Instância global
librarian = LibrarianAgent()

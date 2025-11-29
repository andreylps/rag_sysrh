from langchain_core.tools import tool

from src.services.file_system_service import (
    create_directory,
    list_files_in_directory,
    read_file_content,
    write_file_content,
)
from src.services.rag_service import query_technical_knowledge_base


@tool("search_project_codebase_and_docs")
def search_project_codebase_and_docs_tool(query: str) -> str:
    """
    Searches the project's technical knowledge base (vector store) for code examples, patterns, and documentation.
    Use this tool when you need to understand how to implement something following the project's standards,
    find existing code snippets, or consult architectural decisions.

    Args:
        query: The technical question or search term (e.g., "how to create a fastapi endpoint", "sqlmodel example").
    """
    return query_technical_knowledge_base(query)


@tool("list_rhgov_files")
def list_rhgov_files_tool(relative_path: str = ".") -> str:
    """
    Lista arquivos e pastas em um diretório do projeto 'rh-gov-simulador'.
    Use esta ferramenta para explorar a estrutura de arquivos.

    Args:
        relative_path: Caminho relativo a partir da raiz do projeto (ex: "." para raiz, "app/models" para subpasta).
    """
    try:
        items = list_files_in_directory(relative_path)
        if not items:
            return "Diretório vazio ou não encontrado."
        return "\n".join(items)
    except Exception as e:
        return f"Erro ao listar arquivos: {str(e)}"


@tool("read_rhgov_file")
def read_rhgov_file_tool(relative_path: str) -> str:
    """
    Lê o conteúdo de um arquivo de texto do projeto 'rh-gov-simulador'.
    Use esta ferramenta para ler código fonte, configurações ou documentação.

    Args:
        relative_path: Caminho relativo do arquivo (ex: "app/main.py").
    """
    try:
        return read_file_content(relative_path)
    except Exception as e:
        return f"Erro ao ler arquivo: {str(e)}"


@tool("write_rhgov_file")
def write_rhgov_file_tool(relative_path: str, content: str) -> str:
    """
    Cria ou sobrescreve um arquivo no projeto 'rh-gov-simulador'.
    Use esta ferramenta para criar novos módulos ou atualizar código existente.

    Args:
        relative_path: Caminho relativo do arquivo (ex: "app/services/novo_servico.py").
        content: O conteúdo completo do arquivo em texto.
    """
    try:
        return write_file_content(relative_path, content)
    except Exception as e:
        return f"Erro ao escrever arquivo: {str(e)}"


@tool("create_rhgov_directory")
def create_rhgov_directory_tool(relative_path: str) -> str:
    """
    Cria um novo diretório no projeto 'rh-gov-simulador'.

    Args:
        relative_path: Caminho relativo do novo diretório (ex: "tests/unit").
    """
    try:
        return create_directory(relative_path)
    except Exception as e:
        return f"Erro ao criar diretório: {str(e)}"

import logging
import os
from pathlib import Path
from typing import List

# Configuração de Logging
logger = logging.getLogger(__name__)


def _get_project_root() -> Path:
    """
    Recupera e valida o diretório raiz do projeto simulador a partir da variável de ambiente.
    """
    root_path = os.getenv("RHGOV_PROJECT_ROOT")
    if not root_path:
        raise ValueError(
            "A variável de ambiente 'RHGOV_PROJECT_ROOT' não está definida."
        )

    path_obj = Path(root_path).resolve()
    if not path_obj.exists() or not path_obj.is_dir():
        raise ValueError(
            f"O caminho definido em 'RHGOV_PROJECT_ROOT' não existe ou não é um diretório: {root_path}"
        )

    return path_obj


def _validate_path(relative_path: str) -> Path:
    """
    Valida se o caminho relativo está dentro do diretório raiz do projeto (evita Path Traversal).
    """
    root = _get_project_root()
    # Resolve o caminho absoluto combinando a raiz com o caminho relativo
    target_path = (root / relative_path).resolve()

    # Verifica se o caminho resultante ainda começa com o caminho raiz
    if not str(target_path).startswith(str(root)):
        raise PermissionError(
            f"Acesso negado: O caminho '{relative_path}' tenta acessar fora do diretório do projeto."
        )

    return target_path


def list_files_in_directory(relative_path: str = ".") -> List[str]:
    """
    Lista arquivos e diretórios em um caminho relativo dentro do projeto.

    Args:
        relative_path (str): Caminho relativo a partir da raiz do projeto. Default é a raiz.

    Returns:
        List[str]: Lista de nomes de arquivos e diretórios.
    """
    try:
        target_path = _validate_path(relative_path)

        if not target_path.exists():
            return []

        if not target_path.is_dir():
            raise NotADirectoryError(f"O caminho '{relative_path}' não é um diretório.")

        items = []
        for item in target_path.iterdir():
            prefix = "[DIR] " if item.is_dir() else "[FILE] "
            items.append(f"{prefix}{item.name}")

        return sorted(items)
    except Exception as e:
        logger.error(f"Erro ao listar diretório '{relative_path}': {e}")
        raise


def read_file_content(relative_path: str) -> str:
    """
    Lê o conteúdo de um arquivo de texto.

    Args:
        relative_path (str): Caminho relativo do arquivo.

    Returns:
        str: Conteúdo do arquivo.
    """
    try:
        target_path = _validate_path(relative_path)

        if not target_path.exists():
            raise FileNotFoundError(f"Arquivo não encontrado: {relative_path}")

        if not target_path.is_file():
            raise IsADirectoryError(
                f"O caminho '{relative_path}' é um diretório, não um arquivo."
            )

        return target_path.read_text(encoding="utf-8")
    except Exception as e:
        logger.error(f"Erro ao ler arquivo '{relative_path}': {e}")
        raise


def write_file_content(relative_path: str, content: str) -> str:
    """
    Escreve conteúdo em um arquivo. Cria diretórios pais se necessário.

    Args:
        relative_path (str): Caminho relativo do arquivo.
        content (str): Conteúdo a ser escrito.

    Returns:
        str: Mensagem de sucesso.
    """
    try:
        target_path = _validate_path(relative_path)

        # Cria diretórios pais se não existirem
        target_path.parent.mkdir(parents=True, exist_ok=True)

        target_path.write_text(content, encoding="utf-8")
        return f"Arquivo '{relative_path}' escrito com sucesso."
    except Exception as e:
        logger.error(f"Erro ao escrever arquivo '{relative_path}': {e}")
        raise


def create_directory(relative_path: str) -> str:
    """
    Cria um novo diretório.

    Args:
        relative_path (str): Caminho relativo do diretório.

    Returns:
        str: Mensagem de sucesso.
    """
    try:
        target_path = _validate_path(relative_path)
        target_path.mkdir(parents=True, exist_ok=True)
        return f"Diretório '{relative_path}' criado com sucesso."
    except Exception as e:
        logger.error(f"Erro ao criar diretório '{relative_path}': {e}")
        raise

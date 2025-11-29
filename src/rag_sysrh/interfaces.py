from abc import ABC, abstractmethod
from typing import Any, Dict


class ExternalConnector(ABC):
    """
    Classe base abstrata para conectores com sistemas externos (Jira, GitHub, Azure DevOps).
    """

    @abstractmethod
    def create_issue(self, rcm_data: Dict[str, Any]) -> str:
        """
        Cria uma issue/card no sistema externo.

        Args:
            rcm_data: Dicionário contendo os dados da RCM (título, descrição, etc).

        Returns:
            str: O ID ou URL da issue criada.
        """
        pass

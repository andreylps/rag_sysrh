from typing import Any

from src.agents.sniper_agent import SniperAgent


class CommercialService:
    """
    Serviço para gestão de oportunidades comerciais identificadas pelo Sniper Agent.
    """

    def __init__(self):
        self.sniper_agent = SniperAgent()
        # Persistência em memória para a POC (em produção seria Banco de Dados)
        self._opportunities: list[dict[str, Any]] = []

    async def scan_for_opportunities(self) -> list[dict[str, Any]]:
        """
        Aciona o Sniper Agent para varrer o código e atualiza a lista de oportunidades.
        """
        # Caminho relativo para o simulador (ajustar conforme estrutura de pastas real)
        # Assumindo que o backend roda em RAG_SYSRH e o simulador está em rh-gov-simulador
        target_path = "rh-gov-simulador"

        new_opportunities = await self.sniper_agent.scan_codebase(target_path)

        # Adiciona novas oportunidades à lista (evitando duplicatas exatas se necessário)
        # Para POC, apenas estendemos a lista
        self._opportunities.extend(new_opportunities)

        return new_opportunities

    def get_opportunities(self) -> list[dict[str, Any]]:
        """Retorna todas as oportunidades identificadas."""
        return self._opportunities


# Instância global do serviço para ser usada pelos endpoints
commercial_service = CommercialService()

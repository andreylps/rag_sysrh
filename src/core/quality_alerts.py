from datetime import datetime
from typing import List, Optional

# Lista global para armazenar alertas em memória
_quality_alerts: List[dict] = []


def add_alert(
    message: str, category: str = "stale_issue", issue_number: Optional[int] = None
) -> None:
    """
    Adiciona um novo alerta à lista global.
    """
    alert = {
        "message": message,
        "category": category,
        "issue_number": issue_number,
        "timestamp": datetime.now().isoformat(),
    }
    _quality_alerts.append(alert)


def get_all_alerts() -> List[dict]:
    """
    Retorna todos os alertas armazenados.
    """
    # Retorna uma cópia para evitar modificação externa acidental da lista original
    return list(_quality_alerts)


def clear_alerts() -> None:
    """
    Limpa todos os alertas.
    """
    _quality_alerts.clear()

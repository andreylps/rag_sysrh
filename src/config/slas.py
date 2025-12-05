# src/config/slas.py

# Mapeamento de labels de tipo para tempo máximo de resolução em horas (8h úteis/dia)
ISSUE_SLA_HOURS = {
    "tipo:garantia": 4,  # Imediato/Crítico (0.5 dia)
    "tipo:transf-conhecimento": 24,  # 1 dia
    "tipo:corretiva": 24,  # 1 dia (Crítico)
    "tipo:operacao": 72,  # 3 dias
    "tipo:migracao": 80,  # 10 dias (Ciclo da Sprint)
    "tipo:rcm": 80,  # 10 dias (Ciclo da Sprint)
}

# Tipos críticos que devem furar a fila e entrar na Sprint imediatamente
CRITICAL_SLA_TYPES = [
    "tipo:garantia",
    "tipo:corretiva",
]

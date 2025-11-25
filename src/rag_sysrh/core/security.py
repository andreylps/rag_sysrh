# src/rag_sysrh/core/security.py

from enum import Enum
from typing import List

from fastapi import Depends, Header, HTTPException, status
from src.rag_sysrh.logger import get_logger

logger = get_logger(__name__)


# --- 1. DEFINIÇÃO DE PAPÉIS (ROLES) ---
# Estes são os níveis de acesso que o sistema reconhece.
class UserRole(str, Enum):
    ADMIN = "Adm"  # Acesso total (pode deletar)
    ANALISTA_DOC = "Analista de Documentação"  # Acesso de gestão (pode deletar)
    SOLICITADOR = "Solicitador"  # Acesso básico (apenas visualiza)


# --- 2. MOCK DE SEGURANÇA (PARA DESENVOLVIMENTO) ---
# Esta função extrai o papel do usuário de um cabeçalho HTTP.
# Na FASE 3, ela será substituída pela validação real de um Token JWT.
async def get_current_user_role_mock(
    # O frontend enviará um cabeçalho "X-User-Role" informando o modo atual
    x_user_role: str = Header(default=UserRole.SOLICITADOR, alias="X-User-Role"),
) -> UserRole:
    """
    Simula a identificação do papel do usuário baseada em um cabeçalho simples.
    ATENÇÃO: NÃO SEGURO PARA PRODUÇÃO. Apenas para dev local.
    """
    try:
        # Tenta converter a string do header para um dos Enums válidos
        role_enum = UserRole(x_user_role)
        # logger.debug(f"🔐 Segurança Mock: Papel identificado como [{role_enum.value}]")
        return role_enum
    except ValueError:
        logger.warning(
            f"🔐 Segurança Mock: Tentativa de uso com papel inválido: {x_user_role}"
        )
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Papel de usuário inválido ou não reconhecido: {x_user_role}",
        )


# --- 3. VERIFICADOR DE PERMISSÃO (O "SEGURANÇA" DA PORTA) ---
# Esta é a classe que usaremos nos endpoints para bloquear o acesso.
class RoleChecker:
    def __init__(self, allowed_roles: List[UserRole]):
        self.allowed_roles = allowed_roles

    def __call__(self, user_role: UserRole = Depends(get_current_user_role_mock)):
        # Se o papel do usuário não estiver na lista de permitidos, bloqueia.
        if user_role not in self.allowed_roles:
            logger.warning(
                f"⛔ Acesso negado. Papel '{user_role.value}' não tem permissão para esta rota."
            )
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Você não tem permissão para executar esta ação.",
            )
        return True


# --- Instâncias pré-configuradas para facilitar o uso ---
# Permite apenas Admins
allow_only_admin = RoleChecker([UserRole.ADMIN])
# Permite quem pode gerenciar conhecimento (Adm + Analista)
allow_knowledge_managers = RoleChecker([UserRole.ADMIN, UserRole.ANALISTA_DOC])

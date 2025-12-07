from src.rag_sysrh.infra.cache import get_redis


class ContextManager:
    """
    Gerencia o armazenamento e recuperação de contextos longos (CAG) no Redis.
    """

    PREFIX = "cag:context:"

    async def save_context(self, key: str, content: str, ttl_minutes: int = 60) -> bool:
        """
        Salva um contexto no Redis com expiração definida.
        """
        full_key = f"{self.PREFIX}{key}"
        try:
            redis = get_redis()
            # Redis espera segundos para o TTL
            # set(name, value, ex=seconds)
            await redis.set(full_key, content, ex=ttl_minutes * 60)
            return True
        except Exception as e:
            print(f"Erro ao salvar contexto '{key}' no Redis: {e}")
            return False

    async def get_context(self, key: str) -> str | None:
        """
        Busca um contexto no Redis.
        """
        full_key = f"{self.PREFIX}{key}"
        try:
            redis = get_redis()
            content = await redis.get(full_key)
            return content if content else None
        except Exception as e:
            print(f"Erro ao buscar contexto '{key}' no Redis: {e}")
            return None

    async def invalidate_context(self, key: str) -> bool:
        """
        Remove um contexto do cache.
        """
        full_key = f"{self.PREFIX}{key}"
        try:
            redis = get_redis()
            await redis.delete(full_key)
            return True
        except Exception as e:
            print(f"Erro ao invalidar contexto '{key}' no Redis: {e}")
            return False

    async def invalidate_all(self) -> bool:
        """
        Invalida TODOS os contextos armazenados (chaves 'cag:context:*').
        Útil após re-ingestão de dados.
        """
        try:
            redis = get_redis()
            keys = await redis.keys(f"{self.PREFIX}*")
            if keys:
                await redis.delete(*keys)
            return True
        except Exception as e:
            print(f"Erro ao invalidar todos os contextos: {e}")
            return False


# Singleton para uso na aplicação
cag_service = ContextManager()

import redis.asyncio as redis

from src.rag_sysrh.config import settings


class RedisClient:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super(RedisClient, cls).__new__(cls)
            cls._instance._init_client()
        return cls._instance

    def _init_client(self):
        self.client = redis.Redis(
            host=settings.REDIS_HOST,
            port=settings.REDIS_PORT,
            decode_responses=True,
            encoding="utf-8",
        )

    def get_client(self) -> redis.Redis:
        return self.client

    async def check_connection(self) -> bool:
        try:
            return await self.client.ping()
        except Exception as e:
            print(f"Erro ao conectar no Redis: {e}")
            return False


# Global instance
redis_client = RedisClient()


def get_redis() -> redis.Redis:
    return redis_client.get_client()

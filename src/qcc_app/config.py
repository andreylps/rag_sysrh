import os


class Config:
    SECRET_KEY = (
        os.environ.get("QCC_SECRET_KEY") or "uma-chave-secreta-padrao-muito-segura"
    )
    SCHEDULER_API_ENABLED = True

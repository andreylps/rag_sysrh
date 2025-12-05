import sys
from pathlib import Path

import uvicorn

# Adiciona o diretório raiz ao sys.path
current_dir = Path(__file__).resolve().parent
if str(current_dir) not in sys.path:
    sys.path.insert(0, str(current_dir))

# Adiciona o diretório src ao sys.path também, para garantir
src_dir = current_dir / "src"
if str(src_dir) not in sys.path:
    sys.path.insert(0, str(src_dir))

if __name__ == "__main__":
    print("🚀 Iniciando Backend Híbrido...")
    print(f"📂 Root Dir: {current_dir}")
    print(f"📂 Src Dir: {src_dir}")
    print(f"🐍 Sys Path: {sys.path[:3]}")

    # Importa a app aqui para garantir que o path já está configurado
    try:
        from src.api.main import app

        uvicorn.run(app, host="0.0.0.0", port=8080, reload=False)  # noqa: S104
    except Exception as e:  # noqa: BLE001
        print(f"❌ Erro fatal ao iniciar: {e}")
        import traceback

        traceback.print_exc()

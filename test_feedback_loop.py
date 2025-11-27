import os
import sys

# Adiciona o diretório raiz ao path
sys.path.append(os.getcwd())

from src.services.knowledge_feedback_service import knowledge_feedback_service


def test_feedback_loop():
    print("1. Testando geração de diretrizes (Mock)...")
    # Força a criação de algumas diretrizes mockadas
    directives = [
        "Diretriz de Teste 1: Sempre verificar logs.",
        "Diretriz de Teste 2: Validar inputs.",
    ]
    knowledge_feedback_service.ingest_project_directives(directives)
    print("Diretrizes ingeridas.")

    print("\n2. Testando recuperação de diretrizes...")
    recent = knowledge_feedback_service.get_recent_directives()
    print(f"Diretrizes recuperadas: {recent}")

    if len(recent) >= 2:
        print("✅ Recuperação OK.")
    else:
        print("❌ Falha na recuperação.")


if __name__ == "__main__":
    test_feedback_loop()

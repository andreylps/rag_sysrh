import sys
from pathlib import Path
from unittest.mock import patch

# Add src to path
sys.path.append(str(Path(__file__).parent / "src"))

from rag_sysrh.engine.document_generator import DocumentGenerator
from rag_sysrh.engine.models import (
    AvaliacaoRisco,
    Complexidade,
    ItemFuncional,
    ResultadoSISP,
    TipoFuncao,
)


def test_rcm_generation():
    print("--- Iniciando Teste de Geração de RCM ---")

    # 1. Setup Mocks
    # Mock Neo4j to avoid connection issues or side effects during simple verification
    # We want to verify the FILE GENERATION logic, not the DB connection per se (though that's part of it).
    # Let's mock _get_next_rcm_id to return a predictable ID for file checking.

    with patch.object(
        DocumentGenerator, "_get_next_rcm_id", return_value=(9999, 2025)
    ) as mock_get_id:
        generator = DocumentGenerator()

        # 2. Prepare Data
        item1 = ItemFuncional(
            nome="Manter Usuário",
            tipo=TipoFuncao.ALI,
            descricao="Cadastro de usuários do sistema",
            der_estimado=5,
            rlr_estimado=2,
            justificativa_contagem="Tabela padrão",
            complexidade=Complexidade.BAIXA,
            pf_bruto=7,
        )

        resultado = ResultadoSISP(
            itens_calculados=[item1],
            pf_bruto_total=7,
            pf_liquido_total=7.0,
            prazo_estimado_dias=5,
        )

        risco = AvaliacaoRisco(
            impacto_backend=3,
            impacto_frontend=2,
            risco_migracao=1,
            esforco_testes=3,
            incerteza_requisitos=2,
            justificativa_geral="Risco moderado devido a integrações.",
        )

        solicitacao = "Gostaria de cadastrar usuários."
        diagnostico = "Necessário criar CRUD de usuários."

        # 3. Execute
        print("Gerando RCM...")
        path = generator.gerar_rcm(solicitacao, diagnostico, resultado, risco)

        # 4. Verify
        print(f"Caminho retornado: {path}")

        expected_filename = "9999_2025 - ALTERAÇÃO - MANTER USUÁRIO.docx"
        if path.name == expected_filename:
            print("✅ Nome do arquivo está correto.")
        else:
            print(
                f"❌ Nome do arquivo incorreto. Esperado: {expected_filename}, Obtido: {path.name}"
            )

        if path.exists():
            print("✅ Arquivo criado com sucesso.")
            # Optional: Check content if we had a docx reader here, but existence + name is a good start.
        else:
            print("❌ Arquivo não foi criado.")


if __name__ == "__main__":
    test_rcm_generation()

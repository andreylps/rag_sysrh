import sys
from pathlib import Path

# Adiciona o diretório 'src' ao sys.path
SRC_PATH = Path(__file__).resolve().parent / "src"
if str(SRC_PATH) not in sys.path:
    sys.path.append(str(SRC_PATH))

from rag_sysrh.engine.document_generator import DocumentGenerator
from rag_sysrh.engine.models import (
    Complexidade,
    ItemFuncional,
    ResultadoSISP,
    TipoFuncao,
)


def verify_docs():
    print("--- Verificando Gerador de Documentos ---")

    # Cria dados simulados
    item1 = ItemFuncional(
        nome="Manter Usuário",
        tipo=TipoFuncao.ALI,
        descricao="Cadastro",
        der_estimado=19,
        rlr_estimado=1,
        justificativa_contagem="Teste",
        complexidade=Complexidade.BAIXA,
        pf_bruto=7,
    )

    resultado = ResultadoSISP(
        itens_calculados=[item1],
        pf_bruto_total=7,
        pf_liquido_total=7.0,  # Deflator 1.0
        prazo_estimado_dias=15,
    )

    generator = DocumentGenerator()
    print(f"Template Excel: {generator.excel_template}")
    print(f"Template Word: {generator.word_template}")

    rcm_id = "TESTE-001"
    res = generator.generate_documents(resultado, rcm_id)

    print(f"\nExcel Gerado: {res.memoria_calculo_path}")
    print(f"Word Gerado: {res.rcm_path}")

    # Verifica se arquivos existem
    if res.memoria_calculo_path and "ERRO" not in res.memoria_calculo_path:
        if Path(res.memoria_calculo_path).exists():
            print("✅ Arquivo Excel existe.")
        else:
            print("❌ Arquivo Excel não encontrado.")

    if res.rcm_path and "ERRO" not in res.rcm_path:
        if Path(res.rcm_path).exists():
            print("✅ Arquivo Word existe.")
        else:
            print("❌ Arquivo Word não encontrado.")


if __name__ == "__main__":
    verify_docs()

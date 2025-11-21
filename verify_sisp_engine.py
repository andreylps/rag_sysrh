import sys
from pathlib import Path

# Adiciona o diretório 'src' ao sys.path
SRC_PATH = Path(__file__).resolve().parent / "src"
if str(SRC_PATH) not in sys.path:
    sys.path.append(str(SRC_PATH))

from rag_sysrh.engine.models import ItemFuncional, TipoFuncao
from rag_sysrh.engine.sisp_calculator import SISPCalculator


def verify_engine():
    print("--- Verificando Motor SISP Determinístico ---")

    calculator = SISPCalculator()

    # Caso de Teste 1: ALI Baixa Complexidade (RLR 1, DER 19) -> Esperado: 7 PF
    item1 = ItemFuncional(
        nome="Manter Usuário",
        tipo=TipoFuncao.ALI,
        descricao="Cadastro de usuários",
        der_estimado=19,
        rlr_estimado=1,
        justificativa_contagem="Teste",
    )

    # Caso de Teste 2: EE Alta Complexidade (ALR 3, DER 16) -> Esperado: 6 PF
    item2 = ItemFuncional(
        nome="Login",
        tipo=TipoFuncao.EE,
        descricao="Autenticação",
        der_estimado=16,
        rlr_estimado=3,  # ALR
        justificativa_contagem="Teste",
    )

    print(
        f"Item 1: {item1.nome} ({item1.tipo}) - DER: {item1.der_estimado}, RLR: {item1.rlr_estimado}"
    )
    print(
        f"Item 2: {item2.nome} ({item2.tipo}) - DER: {item2.der_estimado}, RLR: {item2.rlr_estimado}"
    )

    deflator = 0.5
    print(f"\nCalculando com Deflator: {deflator}")

    resultado = calculator.processar_contagem([item1, item2], deflator)

    print("\n--- Resultados ---")
    for item in resultado.itens_calculados:
        print(
            f"[{item.nome}] Complexidade: {item.complexidade}, PF Bruto: {item.pf_bruto}"
        )

    print(f"\nPF Bruto Total: {resultado.pf_bruto_total}")
    print(f"PF Líquido Total: {resultado.pf_liquido_total}")
    print(f"Prazo Estimado: {resultado.prazo_estimado_dias} dias")

    # Asserções básicas
    assert resultado.itens_calculados[0].pf_bruto == 7, "Erro no Item 1"
    assert resultado.itens_calculados[1].pf_bruto == 6, "Erro no Item 2"
    assert resultado.pf_bruto_total == 13, "Erro no Total Bruto"
    assert resultado.pf_liquido_total == 6.5, "Erro no Total Líquido"

    print("\n✅ Verificação Concluída com Sucesso!")


if __name__ == "__main__":
    verify_engine()

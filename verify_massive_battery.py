import subprocess
import sys
import time
from pathlib import Path


def run_test(script_name):
    print(f"\n{'=' * 60}")
    print(f"🚀 INICIANDO TESTE: {script_name}")
    print(f"{'=' * 60}\n")

    start_time = time.time()
    try:
        # Configura ambiente para forçar UTF-8 no IO
        env = sys.modules["os"].environ.copy()
        env["PYTHONIOENCODING"] = "utf-8"

        # Executa o script como um subprocesso
        result = subprocess.run(
            [sys.executable, script_name],
            capture_output=True,
            text=True,
            encoding="utf-8",  # Agora podemos confiar no utf-8
            errors="replace",
            env=env,
        )

        elapsed = time.time() - start_time

        # Imprime a saída (stdout) de forma segura para o console Windows
        try:
            print(result.stdout)
        except UnicodeEncodeError:
            # Se falhar, imprime forçando ascii ou ignorando erros
            print(
                result.stdout.encode(sys.stdout.encoding, errors="replace").decode(
                    sys.stdout.encoding
                )
            )

        if result.returncode == 0:
            print(f"\n[PASS] {script_name}: SUCESSO ({elapsed:.2f}s)")
            return True
        else:
            print(f"\n[FAIL] {script_name}: FALHA (Código {result.returncode})")
            print("--- STDERR ---")
            print(result.stderr)
            return False

    except Exception as e:
        print(f"\n❌ {script_name}: ERRO DE EXECUÇÃO: {e}")
        return False


def main():
    print("--- INICIANDO BATERIA DE TESTES MASSIVOS - RAG SYSRH ---")
    print("======================================================")

    scripts = [
        "verify_strategic_service.py",
        "verify_rcm_generation.py",
        "verify_sisp_calculation.py",
        "verify_guardrail.py",
        "verify_cypher_guardrail.py",
        "verify_bi_agent.py",
        "verify_quality_agent.py",
        "verify_sisp_workflow.py",
        "verify_full_flow.py",
    ]

    results = {}

    for script in scripts:
        if Path(script).exists():
            success = run_test(script)
            results[script] = "PASSOU" if success else "FALHOU"
        else:
            print(f"\n[WARN] Script não encontrado: {script}")
            results[script] = "NÃO ENCONTRADO"

    print("\n\n--- RESUMO DA BATERIA DE TESTES")
    print("==============================")
    all_passed = True
    for script, status in results.items():
        icon = "[PASS]" if status == "PASSOU" else "[FAIL]"
        print(f"{icon} {script}: {status}")
        if status != "PASSOU":
            all_passed = False

    if all_passed:
        print("\nPARABÉNS! TODOS OS TESTES PASSARAM. O SISTEMA ESTÁ ÍNTEGRO.")
        sys.exit(0)
    else:
        print("\nALGUNS TESTES FALHARAM. VERIFIQUE OS LOGS ACIMA.")
        sys.exit(1)


if __name__ == "__main__":
    main()

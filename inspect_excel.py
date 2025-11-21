import pandas as pd

file_path = "data/Layout/SYSRH - Cálculo de Horas RCM 9999-9999 (MODELO).xls"

try:
    # Read the "Memória" sheet
    df = pd.read_excel(file_path, sheet_name="Memória", header=None, nrows=20)

    print("--- First 20 rows of Memória ---")
    print(df.to_string())
except Exception as e:
    print(f"Error reading Excel: {e}")

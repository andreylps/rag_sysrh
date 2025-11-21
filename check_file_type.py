import os
import zipfile

file_path = "data/Layout/SYSRH - Cálculo de Horas RCM 9999-9999 (MODELO).xls"

if os.path.exists(file_path):
    print(f"File exists: {file_path}")
    try:
        with zipfile.ZipFile(file_path, "r") as zip_ref:
            print("It is a valid ZIP file (likely .xlsx).")
            print("Contents:", zip_ref.namelist()[:5])
    except zipfile.BadZipFile:
        print("Not a ZIP file (likely original .xls).")
else:
    print("File not found.")

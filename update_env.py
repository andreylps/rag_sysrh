env_path = ".env"
target_key = "RHGOV_PROJECT_ROOT"
new_value = r"d:\Projeto IA\PROJETOS\rh-gov-simulador"

try:
    with open(env_path, encoding="utf-8") as f:
        lines = f.readlines()

    new_lines = []
    found = False
    for line in lines:
        if line.startswith(f"{target_key}="):
            new_lines.append(f"{target_key}={new_value}\n")
            found = True
        else:
            new_lines.append(line)

    if not found:
        new_lines.append(f"\n{target_key}={new_value}\n")

    with open(env_path, "w", encoding="utf-8") as f:
        f.writelines(new_lines)

    print(f"Updated {target_key} in {env_path}")

except Exception as e:
    print(f"Error: {e}")

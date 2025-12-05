import os
import re

path = os.path.join(r"..\rh-gov-simulador", "app", "core", "config.py")

try:
    with open(path, encoding="utf-8") as f:
        content = f.read()

    if 'extra="ignore"' not in content:
        if "env_ignore_empty=True)" in content:
            content = content.replace(
                "env_ignore_empty=True)", 'env_ignore_empty=True, extra="ignore")'
            )
            print("Replaced using string match.")
        else:
            # Fallback regex to insert before the closing parenthesis of SettingsConfigDict
            # This regex looks for model_config = SettingsConfigDict(...) and inserts the arg
            new_content = re.sub(
                r"(model_config\s*=\s*SettingsConfigDict\([^)]+)",
                r'\1, extra="ignore"',
                content,
            )
            if new_content != content:
                content = new_content
                print("Replaced using regex.")
            else:
                print("Could not find pattern to replace.")

        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
        print("Updated config.py")
    else:
        print("config.py already has extra='ignore'")

except Exception as e:
    print(f"Error: {e}")

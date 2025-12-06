try:
    with open("src/rag_sysrh/app.py", encoding="utf-8") as f:
        content = f.read()

    # The content is double-encoded.
    # It was UTF-8 bytes read as CP1252 (or similar) and then saved as UTF-8.
    # So we have UTF-8 characters that represent the CP1252 interpretation of the original UTF-8 bytes.
    # To reverse:
    # 1. Encode back to CP1252 (getting the original UTF-8 bytes)
    # 2. Decode as UTF-8

    fixed = content.encode("cp1252", errors="replace").decode("utf-8")

    with open("src/rag_sysrh/app.py", "w", encoding="utf-8") as f:
        f.write(fixed)

    print("Successfully repaired encoding.")
except Exception as e:
    print(f"Error repairing encoding: {e}")

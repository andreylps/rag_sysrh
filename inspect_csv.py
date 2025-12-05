filename = "data/solicitacoes.csv"
try:
    with open(filename, "rb") as f:
        content = f.read(2000).decode("latin-1")
        print("--- RAW START ---")
        print(content[:500])
        print("--- RAW END ---")

        lines = content.splitlines()
        for i, line in enumerate(lines):
            if i > 15:
                break
            print(f"Line {i}: {line[:50]}")
            if line.startswith("ID;"):
                print(f"HEADER FOUND AT LINE {i}")
                cols = line.split(";")
                print(f"Column count: {len(cols)}")
                print(f"Columns: {cols}")
except Exception as e:
    print(f"Error: {e}")

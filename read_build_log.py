try:
    with open("build_log.txt", encoding="utf-16") as f:
        print(f.read())
except Exception:
    try:
        with open("build_log.txt", encoding="utf-8") as f:
            print(f.read())
    except Exception as e:
        print(f"Error: {e}")

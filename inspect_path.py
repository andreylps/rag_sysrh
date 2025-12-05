import pandas as pd

solic_path = "data/solicitacoes.csv"
try:
    df = pd.read_csv(
        solic_path,
        sep=";",
        encoding="latin-1",
        skiprows=9,
        on_bad_lines="skip",
        usecols=range(10),
    )
    # Rename columns to find Iteration Path (index 6)
    df.columns = [
        "id",
        "type",
        "title",
        "status",
        "assigned",
        "tipo",
        "iteration_path",
        "desc",
        "created",
        "effort",
    ]

    # Get first non-null iteration path
    path = df["iteration_path"].dropna().iloc[0]
    print(f"Path: '{path}'")
    print(f"Type: {type(path)}")
    print("Characters:")
    for char in str(path):
        print(f"  '{char}' : {ord(char)}")

    # Test replacement
    replaced = str(path).replace(chr(92), "/")
    print(f"Replaced with chr(92): '{replaced}'")

    replaced2 = str(path).replace("\\", "/")
    print(f"Replaced with '\\\\': '{replaced2}'")

except Exception as e:
    print(e)

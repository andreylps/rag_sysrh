try:
    with open(r"..\rh-gov-simulador\app\core\config.py", encoding="utf-8") as f:
        print(f.read())
except Exception as e:
    print(f"Error: {e}")

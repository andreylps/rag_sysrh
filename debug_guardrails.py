import sys

print(f"Python executable: {sys.executable}")
print(f"Python version: {sys.version}")

try:
    import openai

    print(f"OpenAI version: {openai.__version__}")
    print(f"OpenAI file: {openai.__file__}")
except ImportError as e:
    print(f"Error importing openai: {e}")

try:
    import guardrails

    print(f"Guardrails version: {guardrails.__version__}")
    print(f"Guardrails file: {guardrails.__file__}")
except ImportError as e:
    print(f"Error importing guardrails: {e}")
except Exception as e:
    print(f"Error importing guardrails (generic): {e}")

try:
    print("Successfully imported Guard")
except Exception as e:
    print(f"Error importing Guard: {e}")

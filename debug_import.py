import os
import sys

# Add src to sys.path
sys.path.insert(0, os.path.abspath("."))

print("Attempting to import src.api.main...")
try:
    print("✅ Import successful!")
except Exception as e:
    print(f"❌ Import failed: {e}")
    import traceback

    traceback.print_exc()

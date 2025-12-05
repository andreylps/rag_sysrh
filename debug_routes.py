import os
import sys

# Add project root to sys.path
sys.path.insert(0, os.getcwd())
sys.path.insert(0, os.path.join(os.getcwd(), "src"))

try:
    from src.api.main import app

    print("\n--- REGISTERED ROUTES ---")
    for route in app.routes:
        if hasattr(route, "path") and hasattr(route, "methods"):
            print(f"{route.methods} {route.path}")
        elif hasattr(route, "path"):
            print(f"WebSocket/Other {route.path}")
    print("-------------------------\n")
except Exception as e:
    print(f"Error loading app: {e}")

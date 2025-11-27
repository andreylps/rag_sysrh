import os
import sys

# Add project root to sys.path
sys.path.append(os.getcwd())

try:
    from src.rag_sysrh.tools.solicitation_tools import CreateSolicitationTool

    print("✅ Import successful")
    tool = CreateSolicitationTool()
    print(f"✅ Tool instantiated: {tool.name}")
except Exception as e:
    print(f"❌ Import failed: {e}")
    import traceback

    traceback.print_exc()

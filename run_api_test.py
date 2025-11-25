import os
import sys

import uvicorn

# Add src to sys.path
src_path = os.path.join(os.path.dirname(__file__), "src")
if src_path not in sys.path:
    sys.path.insert(0, src_path)

if __name__ == "__main__":
    uvicorn.run("src.api.main:app", host="127.0.0.1", port=8081, reload=False)

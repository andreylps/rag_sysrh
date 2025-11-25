import os
import sys

import uvicorn

# Add src to sys.path to allow imports like 'from rag_sysrh...'
# This is necessary because the code assumes rag_sysrh is a top-level package
src_path = os.path.join(os.path.dirname(__file__), "src")
if src_path not in sys.path:
    sys.path.insert(0, src_path)

if __name__ == "__main__":
    # We run "src.api.main:app"
    # Since we are in the root, 'src' is accessible.
    # The sys.path modification above ensures 'rag_sysrh' imports inside the modules work.
    uvicorn.run("src.api.main:app", host="127.0.0.1", port=8080, reload=True)

import os

from dotenv import load_dotenv

load_dotenv()
print(f"RHGOV_PROJECT_ROOT={os.getenv('RHGOV_PROJECT_ROOT')}")

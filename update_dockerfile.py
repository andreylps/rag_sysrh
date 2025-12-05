import os

dockerfile_content = """FROM python:3.10-slim

WORKDIR /app

# Install system dependencies for WeasyPrint
RUN apt-get update && apt-get install -y \\
    libcairo2 \\
    libpango-1.0-0 \\
    libpangocairo-1.0-0 \\
    libgdk-pixbuf2.0-0 \\
    libffi-dev \\
    shared-mime-info \\
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001"]
"""

target_path = os.path.join(r"..\rh-gov-simulador", "Dockerfile.simulador")

try:
    with open(target_path, "w", encoding="utf-8") as f:
        f.write(dockerfile_content)
    print(f"Updated {target_path}")
except Exception as e:
    print(f"Error: {e}")

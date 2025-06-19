import os
from pathlib import Path

PYTHON_PATH = str(Path(__file__).resolve().parent.parent)
APP_PATH = os.path.join(PYTHON_PATH, "app")
# STORAGE_DIR = os.path.join(os.path.dirname(PYTHON_PATH), "storage")
# os.makedirs(STORAGE_DIR, exist_ok=True)
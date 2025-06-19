import os
from pathlib import Path
from dotenv import load_dotenv
from app.utils.utils import load_yaml
from .setup import PYTHON_PATH, APP_PATH

# Load env file
env_path = Path('.') / '.env'
load_dotenv(env_path, override=True)


class Config:
    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
    OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
    GCP_API_KEY = os.getenv("GCP_API_KEY")

    LLM_CONFIG_PATH = os.path.join(APP_PATH, 'conf', 'llm.yaml')
    LLM_CONFIG = load_yaml(LLM_CONFIG_PATH)
    OPENAI_ENGINE = LLM_CONFIG.get('OPENAI_ENGINE')

    PROMPT_CONFIG_PATH = os.path.join(APP_PATH, 'conf', 'prompt.yaml')
    PROMPT_CONFIG = load_yaml(PROMPT_CONFIG_PATH)

    TEMPLATE_CONFIG_PATH = os.path.join(APP_PATH, 'conf', 'email.yaml')
    TEMPLATE_CONFIG = load_yaml(TEMPLATE_CONFIG_PATH)
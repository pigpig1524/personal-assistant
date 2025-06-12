from app.config import Config
from app.core.llm.openai import create_chat
from app.core.llm.openai import client
from app.models.llm import CreateEventResponse, FindEmailResponse
import json
from app.utils.utils import get_current_date


PROMTPS = Config.PROMPT_CONFIG
PERSONA = Config.PROMPT_CONFIG.get('DETECT_INTENT')
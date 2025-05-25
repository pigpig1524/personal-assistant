from app.config import Config
from app.core.llm.openai import create_chat
import json

PERSONA = Config.PROMPT_CONFIG.get('detect-intent')

class DetectIntentAgent:
    def __init__(self):
        pass

    def detect(self, user_query, lang_code=None):
        conversation = [
            {'role': 'system', 'content': PERSONA},
            {'role': 'user', 'content': user_query}
        ]
        response = create_chat(conversation)
        intent = json.loads(response)
        return intent
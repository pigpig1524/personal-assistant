from openai import OpenAI
from app.config import Config

client = OpenAI(api_key=Config.OPENAI_API_KEY)

def create_chat(conversation,
                tool_list=None, tool_spec=None,
                output_structure=None):
    response = client.chat.completions.create(
        model=Config.OPENAI_ENGINE,
        messages=conversation,
        max_tokens=600
    )
    return response.choices[0].message.content
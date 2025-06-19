from fastapi import APIRouter, Body
from app.core.detect_intent import DetectIntentAgent
from app.core.llm.openai import client
from app.models.llm import Event
from app.models.llm import DetectResult


agent = DetectIntentAgent()
router = APIRouter()

@router.post('/api/detectIntent')
def dectect_intent(user_query: str = Body(..., embed=True),
                   lang_code: str = Body("vi_VN", embed=True),
                   user_id: str = Body("test", embed=True)):
    response = agent.detect(user_query, user_id)
    return response


PROMPT = """
Today is May 28, 2025.
User want to perfrom some action with the calendar, event.
Your mission is to extract the neccessary information
"""


@router.post('/api/parseInfo')
def parse_info(user_query: str = Body(..., embed=True)):
    response = client.beta.chat.completions.parse(
        model='gpt-4o-mini',
        messages=[
            {'role': 'system', 'content': PROMPT},
            {'role': 'user', 'content': user_query}
        ],
        response_format=Event
    )
    return response.choices[0].message.parsed

if __name__ == '__main__':
    print(type(Event))
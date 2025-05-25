from fastapi import APIRouter, Body
from app.core.detect_intent import DetectIntentAgent

agent = DetectIntentAgent()
router = APIRouter()

@router.post('/api/detectIntent')
def dectect_intent(user_query: str = Body(..., embed=True),
                   lang_code: str = Body(..., embed=True)):
    response = agent.detect(user_query)
    return response
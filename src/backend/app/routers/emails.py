from fastapi import APIRouter, Body
from app.models.email import EmailRequest
from app.services.emails import main_process

router = APIRouter()

@router.post('/utils/email')
async def process_email_request(data: EmailRequest = Body(...)):
    response = main_process(data)
    return response
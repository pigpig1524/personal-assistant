from fastapi import APIRouter
from app.models.meeting import MeetingData

router = APIRouter()

@router.post("/api/createMeeting")
def create_meeting(info: MeetingData):
    pass
from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class Intent:
    action: str

class Event(BaseModel):
    summary: str
    description: str
    start_date: datetime
    end_date: datetime

class DetectResult(BaseModel):
    intent: str
    response: str
    action: Optional[str] = None
    data: Optional[dict] = None

class CreateEventResponse(BaseModel):
    response: str
    data: Event

class EmailData(BaseModel):
    subject: Optional[str] = None
    sender: Optional[str] = None
    date: Optional[str] = None

class FindEmailResponse(BaseModel):
    response: str
    data: EmailData

class IntentResponse(BaseModel):
    intent: str
    response: str
    action: Optional[str] = None
    data: Optional[Event] = None
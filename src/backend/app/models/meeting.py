from pydantic import BaseModel
from datetime import datetime

class MeetingData(BaseModel):
    name: str
    start_time: datetime
    end_time: datetime
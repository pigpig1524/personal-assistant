from pydantic import BaseModel
from typing import Optional

class EmailRequest(BaseModel):
    user_query: str
    subject: str
    content: str

class EmailIntent(BaseModel):
    action: str
    template: Optional[str] = None
    note: Optional[str] = None
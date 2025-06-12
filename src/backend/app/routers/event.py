from fastapi import APIRouter, Body

router = APIRouter(tags=['Calendar Event Service'])

@router.post('/api/calendar/createEvent')
def create_event(data = Body(..., embed=True)):
    pass
from fastapi import APIRouter, Body, File, UploadFile
from app.services.event_ocr import process_image

router = APIRouter(tags=['Calendar Event Service'])

@router.post("/utils/ocr")
async def ocr_table(file: UploadFile = File(...)):
    response = await process_image(file)
    return response
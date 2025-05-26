from fastapi import FastAPI
import uvicorn
from app.routers import detect_intent
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()
app.include_router(detect_intent.router)

if __name__ == "__main__":
    uvicorn.run("main:app", host='localhost', port=5001, reload=True)
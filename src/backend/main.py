from fastapi import FastAPI
import uvicorn
from app.routers import detect_intent, event
from fastapi.middleware.cors import CORSMiddleware
from app.log.middleware import LogMiddleWare

app = FastAPI()

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_methods=['*'],
    allow_headers=['*'],
)

app.include_router(detect_intent.router)
app.include_router(event.router)

app.add_middleware(LogMiddleWare)

if __name__ == "__main__":
    uvicorn.run("main:app", host='localhost', port=5001, reload=True)
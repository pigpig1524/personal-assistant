import time
import traceback

from fastapi import Request, status
from starlette.middleware.base import BaseHTTPMiddleware

class LogMiddleWare(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        start_time = time.perf_counter()
        response = await call_next(request)
        end_time = time.perf_counter()
        process_time = end_time - start_time
        response.headers["X-Process-Time"] = str(process_time)
        return response
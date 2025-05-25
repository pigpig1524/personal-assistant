FROM python:3.10-slim

WORKDIR /app/backend
COPY ./backend /app/backend/

RUN pip install -r requirements.txt

#  Expose port
EXPOSE 3000

# Run FastAPI with uvicorn
CMD ["uvicorn", "main:app", "--port=3000", "--host=0.0.0.0"]
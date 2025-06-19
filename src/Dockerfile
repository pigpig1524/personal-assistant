FROM python:3.10-slim

WORKDIR /app/backend
COPY ./backend /app/backend/

RUN pip install -r requirements.txt

#  Expose port
EXPOSE 8080

# Run FastAPI with uvicorn
CMD ["uvicorn", "main:app", "--port=8080", "--host=0.0.0.0"]
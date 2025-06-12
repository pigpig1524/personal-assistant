from google.cloud import firestore
from google.oauth2 import service_account

# Path to your service account key
SERVICE_ACCOUNT_PATH = '../services/service_account.json'


creds = service_account.Credentials.from_service_account_file(SERVICE_ACCOUNT_PATH)
db = firestore.Client(credentials=creds)
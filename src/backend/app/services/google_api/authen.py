# from google.cloud import firestore
# from google.oauth2 import service_account


# SERVICE_ACCOUNT_PATH = '../service_account.json'

# # Path to your service account key
# creds = service_account.Credentials.from_service_account_file(SERVICE_ACCOUNT_PATH)
# db = firestore.Client(credentials=creds)
# collection = db.collection('users')

# from app.db.base import db

# collection = db.collection('users')


# def get_user_creds(uuid: str):
#     doc = collection.document(uuid).get()
#     if not doc.exists:
#         print("User not found")
#     else:
#         print(doc.to_dict())


from google.oauth2 import id_token
from google.auth.transport import requests

# To verify and decode id_token (optional)
ID_TOKEN = "eyJhbGciOiJSUzI1NiIsImtpZCI6ImJiNDM0Njk1OTQ0NTE4MjAxNDhiMzM5YzU4OGFlZGUzMDUxMDM5MTkiLCJ0eXAiOiJKV1QifQ.eyJpc3MiOiJodHRwczovL2FjY291bnRzLmdvb2dsZS5jb20iLCJhenAiOiI0OTYxNTM4MzcwODUtaXFrZ2Y1YnRibmxqam5ub2IxaDBtZm11cm12MTFtOGEuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJhdWQiOiI0OTYxNTM4MzcwODUtNTdxcmRoZ2RsNjFhdnU5aXY3N3JmZm9tZW1yaW4ycHQuYXBwcy5nb29nbGV1c2VyY29udGVudC5jb20iLCJzdWIiOiIxMDA5MTc4MzE3Nzc5MzA0ODI4OTAiLCJlbWFpbCI6ImhvYWltaW5obHQ1NTVAZ21haWwuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsIm5hbWUiOiJIeWRyb2dlbiIsInBpY3R1cmUiOiJodHRwczovL2xoMy5nb29nbGV1c2VyY29udGVudC5jb20vYS9BQ2c4b2NLajlvbVg5V2tvR0dlblRPeTFIUWg4UVU0RW1LSDBEcVZIQ3lEUkhYQnp1Szc2d3c9czk2LWMiLCJnaXZlbl9uYW1lIjoiSHlkcm9nZW4iLCJpYXQiOjE3NDg5NDEyOTgsImV4cCI6MTc0ODk0NDg5OH0.HZRDOMt4Dw_mLaO2iOxDXiPg5U5xgTbWXnhxWcRWz7frVlc6hBWOX1yLK1ZijOxJ4HCI3pcLFKKe6_mm5JLKQB8J9Cy3dbx3uDjhm_BMqDy5tYwFEbVkuBRoPZ1UbNOmeE4gBBTTImsXzM3lfQ99CMT5a7EMyBNwJuKifQEZcoPj3S6BKv18AXHDbxjlX6P6q6ghqXMloYEvbRj2-mukyCGJJBWunF8NTYfzhx5CDDKS8TXwu_0rw_oaHbn2VCyA7il2MYRPyBDGKFbe41iKvti0vMq-Ygg_bf--xTyNgEWyXOpt0MmsXS915iu496JpDnCaKX1nkjY7LfzbfO724w"
CLIENT_ID = "496153837085-57qrdhgdl61avu9iv77rffomemrin2pt.apps.googleusercontent.com"
request = requests.Request()
info = id_token.verify_oauth2_token(ID_TOKEN, request, audience=CLIENT_ID)
print(info)
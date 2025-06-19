# import firebase_admin
# from firebase_admin import credentials, auth
from google.cloud import firestore
import os
from google.cloud.firestore_v1 import ArrayUnion


# Replace this path with your service account JSON file path
# cred = credentials.Certificate("firebase_service_account.json")
# firebase_admin.initialize_app(cred)

os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = 'app/services/firebase_service_account.json'

db = firestore.Client()
collection = db.collection('messages')

# USER_UUID = 'b4cGMRfNVYOkSRogGVsxghD269q2'

# user = auth.get_user(USER_UUID)
# print(user.email)
# print(user.custom_claims)
# print(user.scopes)


def get_messages(user_id: str):
    try:
        doc_ref = collection.document(user_id)
        doc = doc_ref.get()
        if not doc.exists:
            raise Exception()
        doc : dict = doc.to_dict()
        messages = doc.get('messages')
        return messages
    except:
        print(None)
        return []
    
def add_message(user_id: str, messages: list[dict]):
    doc_ref = collection.document(user_id)
    doc = doc_ref.get()
    if not doc.exists:
        doc_ref.set({
            'messages': messages
        })
    else:
        doc_ref.update({
            'messages': ArrayUnion(messages)
        })


if __name__ == '__main__':
    print(get_messages('123')[-4:])
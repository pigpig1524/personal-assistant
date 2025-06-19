import datetime
import os.path

from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

# If modifying these scopes, delete the file token.json.
SCOPES = ["https://www.googleapis.com/auth/calendar.readonly"]


def main():
  """Shows basic usage of the Google Calendar API.
  Prints the start and name of the next 10 events on the user's calendar.
  """
  creds = None
  # The file token.json stores the user's access and refresh tokens, and is
  # created automatically when the authorization flow completes for the first
  # time.
  if os.path.exists("token.json"):
    # creds = Credentials.from_authorized_user_file("token.json", SCOPES)

    # info = {
    #   "token": "ya29.a0AW4XtxilP7ZYDawoVJfw3cmlvvB20GGInd-k7RSCNwV7Uq2zU5gWEacMIquO30yIisxDadgHfasSotn8DUoNDvH2VBgH7cFqx6w2M2-sfygEoMSGiKpjxukbN2iArOMgjjsI6vorgzLP6a52Ek8TjZYaRnhMlH7hItHVP4T_bKultZn16uMjrZf0Z7jlSCMyJkigI5r4nGWGe8maFxS7UH-A2_Z9-zp7mU4pwpLRI9zA71FLWN_hYo66GhIvAAn9hESP788GxXO7mvtgwIGaQr1f0Mxf82pwoPAGxP1mPUwWO714lFvoMFniowBBHBVdKfhJaCgYKAbwSARUSFQHGX2MiNtRv6Fuufl6zN0AgI0IdXA0331",
    #   "token_uri": "https://oauth2.googleapis.com/token"
    # }

    TOKEN="ya29.a0AW4XtxilP7ZYDawoVJfw3cmlvvB20GGInd-k7RSCNwV7Uq2zU5gWEacMIquO30yIisxDadgHfasSotn8DUoNDvH2VBgH7cFqx6w2M2-sfygEoMSGiKpjxukbN2iArOMgjjsI6vorgzLP6a52Ek8TjZYaRnhMlH7hItHVP4T_bKultZn16uMjrZf0Z7jlSCMyJkigI5r4nGWGe8maFxS7UH-A2_Z9-zp7mU4pwpLRI9zA71FLWN_hYo66GhIvAAn9hESP788GxXO7mvtgwIGaQr1f0Mxf82pwoPAGxP1mPUwWO714lFvoMFniowBBHBVdKfhJaCgYKAbwSARUSFQHGX2MiNtRv6Fuufl6zN0AgI0IdXA0331"
    creds = Credentials(token=TOKEN)

  # If there are no (valid) credentials available, let the user log in.
  if not creds or not creds.valid:
    if creds and creds.expired and creds.refresh_token:
      creds.refresh(Request())
    else:
      flow = InstalledAppFlow.from_client_secrets_file(
          "credentials.json", SCOPES
      )
      creds = flow.run_local_server(port=0)
    # Save the credentials for the next run
    with open("token.json", "w") as token:
      token.write(creds.to_json())

  try:
    service = build("calendar", "v3", credentials=creds)

    # Call the Calendar API
    now = datetime.datetime.now(tz=datetime.timezone.utc).isoformat()
    print("Getting the upcoming 10 events")
    events_result = (
        service.events()
        .list(
            calendarId="primary",
            timeMin=now,
            maxResults=10,
            singleEvents=True,
            orderBy="startTime",
        )
        .execute()
    )
    events = events_result.get("items", [])

    if not events:
      print("No upcoming events found.")
      return

    # Prints the start and name of the next 10 events
    for event in events:
      start = event["start"].get("dateTime", event["start"].get("date"))
      print(start, event["summary"])

  except HttpError as error:
    print(f"An error occurred: {error}")


if __name__ == "__main__":
  main()

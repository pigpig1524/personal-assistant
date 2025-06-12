# Import libraries
from datetime import datetime, timedelta
from dateutil import parser # type: ignore
from google.oauth2.service_account import Credentials  # type: ignore
from googleapiclient.discovery import build  # type: ignore
from sentence_transformers import SentenceTransformer  # type: ignore
import pytz
import os
import openai # type: ignore
from datetime import datetime, timedelta
import pytz
from dotenv import load_dotenv # type: ignore
import json


local_tz = pytz.timezone("Asia/Ho_Chi_Minh")


try:
    SERVICE_ACCOUNT_FILE = 'service_account.json'
    SCOPES = ['https://www.googleapis.com/auth/calendar']
    credentials = Credentials.from_service_account_file(SERVICE_ACCOUNT_FILE, scopes=SCOPES)
    service = build('calendar', 'v3', credentials=credentials)
    calendar_id = "vantuankiet.work@gmail.com"
    print("Connected to Google Calendar API.")
except Exception as e:
    print("Failed to connect to Google Calendar API.")
    raise e

def create_event(summary, start, end, location, description):
    """
    Create an event on Google Calendar.
    
    Parameters:
        summary (str): The title or summary of the event.
        start (str): The start datetime of the event in "dd-mm-yyyy HH:MM:SS" format.
        end (str): The end datetime of the event in "dd-mm-yyyy HH:MM:SS" format.
        location (str): The location of the event.
        description (str): A description or note about the event.
    
    Returns:
        None
    """
    start_dt = local_tz.localize(datetime.strptime(start, "%d-%m-%Y %H:%M:%S"))
    end_dt = local_tz.localize(datetime.strptime(end, "%d-%m-%Y %H:%M:%S"))

    event_body = {
        'summary': summary,
        'location': location,
        'description': description,
        'start': {
            'dateTime': start_dt.isoformat(),
            'timeZone': str(local_tz),
        },
        'end': {
            'dateTime': end_dt.isoformat(),
            'timeZone': str(local_tz),
        },
        'reminders': {'useDefault': True},
    }

    time_min = (start_dt - timedelta(hours=6)).strftime("%d-%m-%Y %H:%M:%S")
    time_max = (end_dt + timedelta(hours=1)).strftime("%d-%m-%Y %H:%M:%S")
    
    # events = get_events_in_range(time_min, time_max)
    
    # for event in events:
    #     existing_start = parser.isoparse(event['start']['dateTime']).astimezone(local_tz)
    #     existing_end = parser.isoparse(event['end']['dateTime']).astimezone(local_tz)

    #     if (event.get('summary') == summary and
    #         event.get('location') == location and
    #         event.get('description') == description and
    #         existing_start == start_dt and
    #         existing_end == end_dt):
    #         print("Event already exists.")
    #         return

    created_event = service.events().insert(calendarId=calendar_id, body=event_body).execute()
    print("Event created successfully.")

# 5. Get events within a time range
def get_events_in_range(begin, end):
    """
    Retrieve all events within a specified time range and filter them by start and end times.
    If begin == end, only events that occur at that exact time will be returned.
    Also includes events that start before or at 'begin' and end after or at 'begin'.
    
    Parameters:
        begin (str): The start datetime of the range in "dd-mm-yyyy HH:MM:SS" format.
        end (str): The end datetime of the range in "dd-mm-yyyy HH:MM:SS" format.
    
    Returns:
        list: A list of events that overlap or fall within the specified time range.
    """
    # Convert input times to datetime objects
    begin_dt = local_tz.localize(datetime.strptime(begin, "%d-%m-%Y %H:%M:%S"))
    end_dt = local_tz.localize(datetime.strptime(end, "%d-%m-%Y %H:%M:%S"))

    # Convert datetime objects to ISO format
    begin_iso = begin_dt.isoformat()
    end_iso = end_dt.isoformat()

    # Retrieve all events in the specified time range
    events = service.events().list(
        calendarId=calendar_id,
        timeMin=begin_iso,
        timeMax=end_iso,
        singleEvents=True,
        orderBy='startTime'
    ).execute()

    # Filter events to include those that start before or at 'begin' and end after or at 'begin'
    result = []
    for event in events.get('items', []):
        s = parser.isoparse(event['start']['dateTime']).astimezone(local_tz)
        e = parser.isoparse(event['end']['dateTime']).astimezone(local_tz)

        # Check if event starts before or at 'begin' and ends after or at 'begin'
        if s <= begin_dt <= e:
            result.append(event)
        # Check if the event overlaps with the given time range
        elif s < end_dt and e > begin_dt:  # Overlap condition
            result.append(event)
    
    return result


if __name__ == "__main__":
    create_event(
        summary="Khai thác dữ liệu và ứng dụng",
        start="08-04-2025 07:30:00",
        end="08-04-2025 11:00:00",
        location="HCMUS F106",
        description="GV: Lê Hoài Bắc"
    )
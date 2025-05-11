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
# from llama_index.llms.openai import OpenAI # type: ignore
# from llama_index.core.tools import FunctionTool # type: ignore
# from llama_index.core.agent import FunctionCallingAgentWorker, AgentRunner # type: ignore
# from llama_index.core.agent import AgentRunner # type: ignore

# Load model
model = SentenceTransformer("distiluse-base-multilingual-cased-v2")

# Load API key
load_dotenv()
openai.api_key = os.getenv("openai_api_key")

# Timezone
local_tz = pytz.timezone("Asia/Ho_Chi_Minh")

# Google Calendar API setup
try:
    SERVICE_ACCOUNT_FILE = 'service_account.json'
    SCOPES = ['https://www.googleapis.com/auth/calendar']
    credentials = Credentials.from_service_account_file(SERVICE_ACCOUNT_FILE, scopes=SCOPES)
    service = build('calendar', 'v3', credentials=credentials)
    calendar_id = "whitemouse.aihcmus@gmail.com"
    print("Connected to Google Calendar API.")
except Exception as e:
    print("Failed to connect to Google Calendar API.")
    raise e

# Support functions
def get_now():
    """
    Get the current time in the local timezone (Asia/Ho_Chi_Minh).
    
    Returns:
        datetime: The current datetime object localized to the specified timezone.
    """
    return datetime.now(local_tz)

def get_this_week_range():
    """
    Get the start and end datetime of the current week (Monday to Sunday).
    
    Returns:
        tuple: A tuple containing the start and end datetime of the current week in string format ("dd-mm-yyyy HH:MM:SS").
    """
    now = get_now()
    start = now - timedelta(days=now.weekday())
    start = start.replace(hour=0, minute=0, second=0, microsecond=0)
    end = start + timedelta(days=6, hours=23, minutes=59, seconds=59)
    return (
        start.strftime("%d-%m-%Y %H:%M:%S"),
        end.strftime("%d-%m-%Y %H:%M:%S")
    )

def get_current_day():
    """
    Get the current day in "dd-mm-yyyy" format.
    
    Returns:
        str: Current date formatted as "dd-mm-yyyy".
    """
    return get_now().strftime("%d-%m-%Y")

def GetInfoDay():
    """
    Get the current date and the day of the week (in Vietnamese).
    
    Returns:
        tuple: The current date as a string and the name of the day in Vietnamese.
    """
    now = datetime.now(local_tz)
    return now.strftime("%d-%m-%Y %H:%M:%S"), ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'][now.weekday()]

def get_current_time():
    """
    Get the current time in "dd-mm-yyyy HH:MM:SS" format.
    
    Returns:
        str: Current time formatted as "dd-mm-yyyy HH:MM:SS".
    """
    return get_now().strftime("%d-%m-%Y %H:%M:%S")

def add_a_time(days=0, hours=0, minutes=0, seconds=0):
    """
    Add a specified amount of time (days, hours, minutes, seconds) to the current time.
    
    Parameters:
        days (int): The number of days to add. Default is 0.
        hours (int): The number of hours to add. Default is 0.
        minutes (int): The number of minutes to add. Default is 0.
        seconds (int): The number of seconds to add. Default is 0.
    
    Returns:
        str: The new time after adding the specified time, formatted as "dd-mm-yyyy HH:MM:SS".
    """
    result = get_now() + timedelta(days=days, hours=hours, minutes=minutes, seconds=seconds)
    return result.strftime("%d-%m-%Y %H:%M:%S")

# Calendar functions

# 1. Create an event
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
    
    events = get_events_in_range(time_min, time_max)
    
    for event in events:
        existing_start = parser.isoparse(event['start']['dateTime']).astimezone(local_tz)
        existing_end = parser.isoparse(event['end']['dateTime']).astimezone(local_tz)

        if (event.get('summary') == summary and
            event.get('location') == location and
            event.get('description') == description and
            existing_start == start_dt and
            existing_end == end_dt):
            print("Event already exists.")
            return

    created_event = service.events().insert(calendarId=calendar_id, body=event_body).execute()
    print("Event created successfully.")
    # print("Event ID:", created_event['id'])

# 2. Delete an event by ID
def delete_event(event_id):
    """
    Delete an event from Google Calendar by event ID.
    
    Parameters:
        event_id (str): The ID of the event to delete.
    
    Returns:
        None
    """
    try:
        service.events().delete(calendarId=calendar_id, eventId=event_id).execute()
        print(f"Event with ID {event_id} deleted successfully.")
    except Exception as e:
        print(f"Failed to delete event: {e}")
        
def delete_events(events):
    """
    Delete one or more events from Google Calendar by event ID(s).
    
    Parameters:
        event_ids (str or list): A single event ID or a list of event IDs to delete.
    
    Returns:
        str: Message indicating the result of the deletion.
    """
    if isinstance(events, list):
        for event in events:
            delete_event(event['id'])

# 3. Search for an event by ID
def search_event_by_id(events, event_id):
    """
    Search for an event by its ID from a list of events.
    
    Parameters:
        events (list): A list of event dictionaries retrieved from Google Calendar.
        event_id (str): The unique ID of the event to search for.
    
    Returns:
        list: A list containing the event that matches the specified ID.
    """
    return [e for e in events if e.get('id') == event_id]

# 4. Search for events by title using semantic similarity
def search_event_by_title(events, title, threshold=0.8):
    """
    Search for events by title using semantic similarity. This function uses Sentence-BERT to calculate similarity scores between the event titles and the given title.
    
    Parameters:
        events (list): A list of event dictionaries retrieved from Google Calendar.
        title (str): The title to search for.
        threshold (float): The minimum similarity score required to consider an event as a match. Default is 0.5.
    
    Returns:
        list: A list of events that have a similarity score equal to or above the threshold.
    """
    results = []
    for event in events:
        try:
            score = round(float(model.similarity(
                model.encode(title),
                model.encode(event.get('summary', ''))
            )[0][0]), 4)

            if score >= threshold:
                results.append((event, score))

            results.sort(key=lambda x: x[1], reverse=True)
        except:
            pass
    return [event for event, _ in results]

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

# 6. Display a list of events in readable format
def display_events(events):
    """
    Display a list of events in a human-readable format.
    
    Parameters:
        events (list): A list of events to display.
    
    Returns:
        None
    """
    for event in events:
        start = parser.isoparse(event['start']['dateTime']).astimezone(local_tz)
        end = parser.isoparse(event['end']['dateTime']).astimezone(local_tz)

        print(f"\nEvent ID        : {event.get('id', 'N/A')}")
        print(f"Title           : {event.get('summary', '[No Title]')}")
        print(f"Location        : {event.get('location', 'Unknown')}")
        print(f"Description     : {event.get('description', '')}")
        print(f"Start           : {start.strftime('%d-%m-%Y %H:%M:%S')}")
        print(f"End             : {end.strftime('%d-%m-%Y %H:%M:%S')}")

# Get range from prompt
def extract_time_from_prompt(prompt: str) -> dict:
    now_str, weekday_str = GetInfoDay()
    messages = [
        {
            "role": "system",
            "content": f"""Now is {now_str} ({weekday_str}).

                        You are an assistant that extracts meaning from Vietnamese time expressions.

                        Return format (JSON):
                        {{
                        "day": "text like 'thứ sáu tới' or 'tuần tới'" BUT if can retunr 2 day in this example [thứ 2, thứ 3] mean from monday to tuesday
                        "time": "a single string (like '08:00') or array ['08:00', '10:00'] for time range, or 'morning'/'afternoon'/'evening', or null"
                        }}

                        Examples:
                        - "thứ sáu tới" -> {{ "day": "thứ sáu tới", "time": null }}
                        - "sáng chủ nhật tuần này" -> {{ "day": "chủ nhật tuần này", "time": "morning" }}
                        - "thứ hai tuần sau lúc 14h30" -> {{ "day": "thứ hai tuần sau", "time": "14:30" }}
                        - "cuối tuần" -> {{ "day": "chủ nhật tuần này", "time": null }}
                        - "chiều mai" -> {{ "day": "ngày mai", "time": "afternoon" }}
                        - "ngày mốt" -> {{ "day": "ngày mốt", "time": null }}
                        - "ngày kia" -> {{ "day": "ngày kia", "time": null }}
                        - "tối hôm kia" -> {{ "day": "hôm kia", "time": "evening" }}
                        - "tuần tới" -> {{ "day": "tuần tới", "time": null }}
                        - "tuần sau" -> {{ "day": "tuần sau", "time": null }}
                        - "8 giờ" -> {{ "day": "hôm nay", "time": "08:00" }}
                        - "5 giờ tới 10 giờ" -> {{ "day": "hôm nay", "time": ["05:00", "10:00"] }}
                        - "mai tới hết tuần" -> {{"day": "ngày mai", "time":"hết tuần"}}
                        - "thứ 2 tuần sau tới hết tuần sau" -> {{'day' : ["thứ hai tới, chủ nhật tới"] , "time" : "null"}}
                        - "thứ 3 tới thứ 7 " -> {{'day' : ["thứ ba", "thứ bảy"] , "time" : "null"}}
                        - "ngày 15 tháng 9 " -> {{ "day": "15:09", "time": null }}
                        - "hôm nay tới hết tuần " ->{{ "day": ['hôm nay','chủ nhật'], "time": null }}
                        - "mai tới hết tuần" ->{{ "day": ['ngày mai','chủ nhật'], "time": null }}
                        - "thứ 2 tuần sau từ 5h tới 21h -> {{ "day": thứ hai tuần sau, "time": ["05:00","21:00"] }}
                        Only respond with valid JSON, no explanation.
                        """
                                },
                                {"role": "user", "content": prompt}
                            ]

    try:
        response = openai.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=messages,
            temperature=0
        )
        parsed = json.loads(response.choices[0].message.content.strip())
        return calculate_time(parsed)
    except Exception as e:
        return {"error": str(e)}

# Step 2: Calculate exact datetime
def calculate_time(parsed: dict) -> list:
    import re

    now = datetime.now(local_tz)
    weekday_map = {
        "thứ hai": 0, "thứ ba": 1, "thứ tư": 2, "thứ năm": 3,
        "thứ sáu": 4, "thứ bảy": 5, "chủ nhật": 6
    }
    if isinstance(parsed.get("day", ""), list):
        first_day = parsed["day"][0]
        last_day = parsed["day"][-1]
        
        dict_1 = {
            'day': first_day,
            'time': parsed.get("time")
        }
        dict_2 = {
            'day': last_day,
            'time': parsed.get("time")
        }

        start_time = calculate_time(dict_1)[0]  
        end_time = calculate_time(dict_2)[1]  

        return [start_time, end_time]
    phrase = parsed.get("day", "").lower()
    time_str = parsed.get("time")
    target_day = None

    if ":" in phrase and len(phrase.split(":")) == 2:
        try:
            day, month = phrase.split(":")
            day = int(day)
            month = int(month)
            target_day = datetime(now.year, month, day)
        except ValueError:
            return [None, None]

    if "hôm nay" in phrase:
        target_day = now
    elif "ngày mai" in phrase:
        target_day = now + timedelta(days=1)
    elif "ngày mốt" in phrase:
        target_day = now + timedelta(days=2)
    elif "ngày kia" in phrase:
        target_day = now + timedelta(days=3)
    elif "hôm qua" in phrase:
        target_day = now - timedelta(days=1)
    elif "hôm kia" in phrase:
        target_day = now - timedelta(days=2)

    elif "tuần tới" in phrase or "tuần sau" in phrase:
        monday_next_week = now + timedelta(days=(7 - now.weekday())) 
        monday_next_week = monday_next_week + timedelta(weeks=1)  
        sunday_next_week = monday_next_week + timedelta(days=6)  

        start = monday_next_week.replace(hour=0, minute=0, second=0)
        end = sunday_next_week.replace(hour=23, minute=59, second=59)

        return [
            start.strftime("%d-%m-%Y %H:%M:%S"),
            end.strftime("%d-%m-%Y %H:%M:%S")
        ]

    elif "từ" in phrase and "tới" in phrase:
        days = re.findall(r"thứ\s*(\d+)|chủ nhật", phrase)  
        
        if len(days) == 2:
            start_day_name = days[0]
            end_day_name = days[1]

            start_day_index = 6 if start_day_name == "chủ nhật" else int(start_day_name) - 1
            end_day_index = 6 if end_day_name == "chủ nhật" else int(end_day_name) - 1


            start_day = now + timedelta(days=(start_day_index - now.weekday()) % 7)  
            end_day = now + timedelta(days=(end_day_index - now.weekday()) % 7)      


            if start_day > end_day:
                end_day = end_day + timedelta(weeks=1)


            start = start_day.replace(hour=0, minute=0, second=0)
            end = end_day.replace(hour=23, minute=59, second=59)

            return [
                start.strftime("%d-%m-%Y %H:%M:%S"),
                end.strftime("%d-%m-%Y %H:%M:%S")
            ]


    if "tới hết tuần" in phrase or "từ hôm nay đến hết tuần" in phrase:
        if "ngày mai" in phrase:
            start_day = now + timedelta(days=1) 
        else:
            start_day = now  

        end_day = now + timedelta(days=(6 - now.weekday()))

        start = start_day.replace(hour=0, minute=0, second=0)
        end = end_day.replace(hour=23, minute=59, second=59)

        return [
            start.strftime("%d-%m-%Y %H:%M:%S"),
            end.strftime("%d-%m-%Y %H:%M:%S")
        ]

    weekday_match = re.search(r"thứ\s*(\d+)\s*tới", phrase)
    if weekday_match:
        target_weekday = int(weekday_match.group(1)) - 1  
        days_until_target = (target_weekday - now.weekday()) % 7


        if days_until_target == 0:
            days_until_target += 7  

        target_day = now + timedelta(days=days_until_target)
        start = target_day.replace(hour=0, minute=0, second=0)
        end = target_day.replace(hour=23, minute=59, second=59)
        return [
            start.strftime("%d-%m-%Y %H:%M:%S"),
            end.strftime("%d-%m-%Y %H:%M:%S")
        ]

    if not target_day:
        for key, target_N in weekday_map.items():
            if key in phrase:
                current_N = now.weekday()
                if "tuần này" in phrase:
                    delta = target_N - current_N
                else:
                    delta = (target_N - current_N + 7) % 7 or 7
                target_day = now + timedelta(days=delta)
                break

    if not target_day:
        return [None, None]

    if time_str is None:
        start = target_day.replace(hour=0, minute=0, second=0)
        end = target_day.replace(hour=23, minute=59, second=59)
    elif isinstance(time_str, list) and len(time_str) == 2:
        try:
            h1, m1 = map(int, time_str[0].split(":"))
            h2, m2 = map(int, time_str[1].split(":"))
            start = target_day.replace(hour=h1, minute=m1, second=0)
            end = target_day.replace(hour=h2, minute=m2, second=0)
        except:
            return [None, None]
    elif time_str == "morning":
        start = target_day.replace(hour=0, minute=0, second=0)
        end = target_day.replace(hour=11, minute=59, second=59)
    elif time_str == "afternoon":
        start = target_day.replace(hour=12, minute=0, second=0)
        end = target_day.replace(hour=17, minute=59, second=59)
    elif time_str == "evening":
        start = target_day.replace(hour=18, minute=0, second=0)
        end = target_day.replace(hour=23, minute=59, second=59)
    else:
        try:
            hour, minute = map(int, time_str.split(":"))
            start = target_day.replace(hour=hour, minute=minute, second=0)
            end = start + timedelta(minutes=59)
        except:
            return [None, None]

    fmt = "%d-%m-%Y %H:%M:%S"
    return [start.strftime(fmt), end.strftime(fmt)]

def extract_event_details_from_prompt(prompt: str) -> dict:
    openai.api_key = os.getenv("openai_api_key")

    messages = [
        {
            "role": "system",
            "content": """
                You are an assistant that extracts meeting/event details from natural Vietnamese text.

                Your task is to parse the input and return the following fields in JSON:
                {
                "summary": "main title or purpose of the event, or null if not found",
                "location": "where the event will happen, or null if not found",
                "description": "any extra notes or description, or null if not found"
                }

                Only return valid JSON. Do not include any explanation.

                Examples (in Vietnamese):
                - "Tạo lịch họp với team vào chiều mai ở phòng họp A, ghi chú gửi báo cáo trước" =>
                {
                "summary": "lịch họp với team",
                "location": "phòng họp A",
                "description": "gửi báo cáo trước"
                }

                - "Sáng thứ ba họp bàn đồ án" =>
                {
                "summary": "họp bàn đồ án",
                "location": null,
                "description": null
                }

                - "Lịch gặp khách hàng ở Highlands Coffee, nội dung chốt hợp đồng" =>
                {
                "summary": "lịch gặp khách hàng",
                "location": "Highlands Coffee",
                "description": "nội dung chốt hợp đồng"
                }
                - "tuần tới về nhà nghỉ lễ không đi học" =>
                {
                "summary": "về nhà",
                "location": null,
                "description": "nghỉ lễ không đi học"
                }
        """
        },
        {"role": "user", "content": prompt}
    ]

    try:
        response = openai.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=messages,
            temperature=0
        )
        return json.loads(response.choices[0].message.content.strip())
    except Exception as e:
        return {"error": str(e)}
    
def format_prompt_to_create(promt):
    time_info = extract_time_from_prompt(promt)
    event_details = extract_event_details_from_prompt(promt)
    return event_details['summary'], time_info[0], time_info[1] , event_details['location'], event_details['description']

def switch_task(prompt: str) -> dict:
    openai.api_key = os.getenv("openai_api_key")

    messages = [
        {
            "role": "system",
            "content": """
                You are an assistant that extracts information from natural Vietnamese text.

                Your task is to analyze the input and return the corresponding tool number based on the tool dictionary below:
                {
                    "1": "create_event",  # Create an event
                    "2": "delete_event_all_in_range",  # Delete all events within a specific time range
                    "3": "delete_event_title_in_range",  # Delete events by title within a specific time range
                    "4": "search_in_range_without_title",  # Search events within a specific time range (no title filter)
                    "5": "search_in_range_with_title",  # Search events within a specific time range (with title filter)
                    "6": "None",  # For non-action requests like "go to sleep" or unrelated queries
                }

                Only return a valid JSON object. Do not include any explanations.

                Example (in Vietnamese):
                - "Tạo lịch họp với team vào chiều mai" => 
                    {
                        "tool_number": 1
                    }
                - "Xóa tất cả sự kiện trong tuần tới" => 
                    {
                        "tool_number": 2
                    }
                - "Xóa lịch họp hôm nay" =>
                    {
                        "tool_number": 3
                    }
                - "Học máy học vào hôm nào " => 
                    {
                        "tool_number": 5
                    }
                - "Trong tuần này có những việc gì" => 
                    {
                        "tool_number": 4
                    }
                - "Tìm kiếm sự kiện 'họp team' trong tuần tới" => 
                    {
                        "tool_number": 5
                    }
                - "Xóa lịch môn học máy" => 
                    {
                        "tool_number": 3
                    }
                - "Đi ngủ" =>
                    {
                        "tool_number": 6
                    }
                - "Hiển thị danh sách các sự kiện vào thứ hai tuần sau" => 
                    {
                        "tool_number": 4
                    }
                - "Tạo lịch học môn học máy vào sáng thứ hai tuần sau lúc 8h tới 11h" =>
                    {
                        "tool_number": 1
                    }
                - "Xóa lịch học môn học Python vào tuần sau" =>
                    {
                        "tool_number": 3
                    }
                - "Tìm tất cả sự kiện về học máy trong tuần sau" =>
                    {
                        "tool_number": 5
                    }
                - "Tạo lịch họp báo cáo vào sáng thứ ba tuần này từ 10h tới 12h" =>
                    {
                        "tool_number": 1
                    }
                - "Tìm kiếm sự kiện học Python vào tháng sau" =>
                    {
                        "tool_number": 5
                    }
                - "Hiển thị lịch họp nhóm vào thứ hai tuần sau" =>
                    {
                        "tool_number": 4
                    }
                - "Tìm kiếm sự kiện đào tạo vào cuối tuần này" =>
                    {
                        "tool_number": 5
                    }
                - "Tạo lịch họp khách hàng vào thứ 6 tuần này lúc 9h tới 12h tại phòng A" =>
                    {
                        "tool_number": 1
                    }
                - "Hiển thị danh sách sự kiện từ ngày mai đến hết tuần" =>
                    {
                        "tool_number": 4
                    }
                - "lịch hôm nay" =>
                    {
                        "tool_number": 5
                    }
                - "lịch họp môn học máy hôm nay" =>
                    {
                        "tool_number": 4
                    } 
                Your response should be the **tool number** corresponding to the action needed.
            """
        },
        {"role": "user", "content": prompt}
    ]

    try:
        response = openai.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=messages,
            temperature=0
        )
        return json.loads(response.choices[0].message.content.strip())
    except Exception as e:
        return {"error": str(e)}  

def handle_time_and_events(prompt):
    info = format_prompt_to_create(prompt)
    begin_time = info[1]
    end_time = info[2]

    if not begin_time or not end_time:
        begin_time = get_now()
        end_time = begin_time + timedelta(days=6, hours=23, minutes=59, seconds=59)

    if isinstance(begin_time, str):
        begin_time = datetime.strptime(begin_time, "%d-%m-%Y %H:%M:%S")
    if isinstance(end_time, str):
        end_time = datetime.strptime(end_time, "%d-%m-%Y %H:%M:%S")

    begin_time = begin_time.strftime("%d-%m-%Y %H:%M:%S")
    end_time = end_time.strftime("%d-%m-%Y %H:%M:%S")

    events = get_events_in_range(begin_time, end_time)
    
    return events, info[0]

def Run(prompt):
    tool_number = switch_task(prompt)['tool_number']
    
    if tool_number == 1:
        input_event = format_prompt_to_create(prompt)
        summary, start, end, location, description = input_event
        create_event(summary, start, end, location, description)

    elif tool_number in [2, 3]:
        events, title = handle_time_and_events(prompt)
        
        if tool_number == 3:
            if not title:
                events = search_event_by_title(events, title, threshold=0.6)
            else:
                events = search_event_by_title(title, events)
        if events:
            delete_events(events)
        else:
            print("No events found in the specified range.")
    
    elif tool_number == 4:
        events, _ = handle_time_and_events(prompt)
        display_events(events)

    elif tool_number == 5:
        events, title = handle_time_and_events(prompt)
        if not title:
            events = search_event_by_title(events, title, threshold=0.6)
        else:
            events = search_event_by_title(title, events)
        display_events(events)
    
    elif tool_number == 6:
        print('The request is unclear')


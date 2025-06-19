import requests
import json
import os
from dotenv import load_dotenv#type:ignore
import openai #type:ignore
import base64
from fastapi import UploadFile
from app.config import Config

API_URL = f"https://vision.googleapis.com/v1/images:annotate?key={Config.GCP_API_KEY}"

def file_to_b64(file: UploadFile):
    content = file.file.read()
    image_base64 = base64.b64encode(content).decode('utf-8')
    return image_base64

def process(image_base64):
    payload = {
        "requests": [
            {
                "image": {
                    "content": image_base64
                },
                "features": [
                    {
                        "type": "TEXT_DETECTION",
                        "maxResults": 1
                    }
                ]
            }
        ]
    }

    response = requests.post(API_URL, json=payload)
    temp = []
    response_json = response.json()

    if 'error' in response_json:
        print(f"Error: {response_json['error']}")
    else:
        text_annotations = response_json['responses'][0].get('textAnnotations', [])
        if text_annotations:
            for annotation in text_annotations[1:]:
                description = annotation['description']
                bounding_poly = annotation['boundingPoly']
                vertices = bounding_poly['vertices']
                
                top_left = vertices[0]
                x_coord = top_left.get('x', 0)  
                y_coord = top_left.get('y', 0)
                temp.append([[x_coord, y_coord], description])
        else:
            print("No text detected.")


    def group_text_by_rows(ocr_data, row_threshold=10):
        """
        Group OCR results by rows based on Y coordinates
        """
        if not ocr_data:
            return []
        
        sorted_data = sorted(ocr_data, key=lambda x: x[0][1])
        
        rows = []
        current_row = []
        current_y = None
        
        for item in sorted_data:
            y_coord = item[0][1]
            
            if current_y is None:
                current_y = y_coord
                current_row = [item]
            elif abs(y_coord - current_y) <= row_threshold:
                current_row.append(item)
            else:
                if current_row:
                    rows.append(current_row)
                current_row = [item]
                current_y = y_coord
        
        if current_row:
            rows.append(current_row)
        
        return rows

    def reconstruct_table_structure(ocr_data):
        """
        Reconstruct table structure from OCR data using coordinates
        """
        rows = group_text_by_rows(ocr_data)

        structured_rows = []
        for row in rows:
            sorted_row = sorted(row, key=lambda x: x[0][0])
            row_text = []
            for item in sorted_row:
                row_text.append(item[1])
            structured_rows.append(' | '.join(row_text))
        
        return '\n'.join(structured_rows)

    def extract_exam_events(structured_text):
        """
        Extract individual exam events from structured text
        """
        lines = structured_text.split('\n')
        events = []

        for i, line in enumerate(lines):
            if line.strip():
                if ('CSC' in line and 
                    any(date_pattern in line for date_pattern in ['2025', '/']) and
                    any(time_pattern in line for time_pattern in ['g', ':'])):
                    events.append(line)
        
        return events

    def format_OCR(events_data) -> dict:
        """
        Format OCR results into structured event data using coordinate information
        """
        if not isinstance(events_data, list) or not events_data:
            return {"error": "No OCR data to process"}

        structured_text = reconstruct_table_structure(events_data)
        exam_events = extract_exam_events(structured_text)
        for i, event in enumerate(exam_events):
            pass
        
        if not exam_events:
            return {"error": "No exam events found"}

        all_events = []
        for event_text in exam_events:
            messages = [
                {
                    "role": "system",
                    "content": """
                        You are an assistant who extracts exam details from a single line of Vietnamese exam schedule data.
                        
                        The input is one line from an exam schedule table with fields separated by " | ". 
                        The typical structure from the table columns is: [Mã MH] | [Tên môn học] | [Mã lớp] | [Ngày thi] | [Giờ thi] | [Số SV] | [Mã CB] | [Họ tên CBGD] | [Tg thi] | [Phòng] | [Khóa]
                        
                        Please parse the information and return the exam in JSON format with the following fields:
                            - "summary": The course name (combine course name words, e.g., "Phân | tích | dữ | liệu | thông | minh" becomes "Phân tích dữ liệu thông minh")
                            - "start": The exam date and time (format "DD-MM-YYYY HH:mm:ss", convert "g" to ":", e.g., "13g30" becomes "13:30:00")
                            - "end": Calculate end time by adding exam duration ("Tg thi" column, usually 120 minutes) to start time
                            - "location": The exam room from "Phòng" column (like "F101", "LT", etc.) if not return null
                            - "description": short of this event
                        
                        Important parsing notes:
                        - Course codes start with "CSC" followed by numbers
                        - Course names are broken into separate words separated by " | "
                        - Times use "g" instead of ":" (e.g., "13g30" means "13:30", "07g45" means "07:45")
                        - Dates are in DD/MM/YYYY format
                        - Exam duration is typically 120 minutes (2 hours)
                        - Instructor names are fragmented like "Nguyễn | Tiến | Huy" or "Lê | Hoài | Bắc"
                        - Room info appears near the end of the line
                        
                        Example input: "CSC17001 | Phân | tích | dữ | liệu | thông | minh | 22 | 24 | 27/06/2025 | 13g30 | 70 | 1951 | Nguyễn | Tiến | Huy | 120 | LT | 2022"
                        
                        Your output should be ONLY valid JSON, without any additional explanation.
                    """
                },
                {"role": "user", "content": event_text}
            ]
            
            try:
                client = openai.OpenAI(api_key=os.getenv("openai_api_key"))
                response = client.chat.completions.create(
                    model="gpt-3.5-turbo",
                    messages=messages,
                    temperature=0
                )
                
                content = response.choices[0].message.content.strip()
                
                try:
                    event_json = json.loads(content)
                    all_events.append(event_json)
                except json.JSONDecodeError as je:
                    continue
                    
            except Exception as e:
                print(f"OpenAI API error for event: {e}")
                continue
        
        return all_events if all_events else {"error": "No events could be processed"}

    if temp:
        formatted_events = format_OCR(temp)
        # print("Formatted Events:", formatted_events)
        names = ', '.join([event['summary'] for event in formatted_events])
        return {'intent': 'CALENDAR',
                'response': 'Mình sẽ tạo cho bạn một danh sách các sự kiện: ' + names,
                'action': 'CREATE_EVENT',
                'data': formatted_events}
    else:
        # print("No OCR data to process")
        return {'status': 'error'}


async def process_image(file: UploadFile):
    image_base64 = file_to_b64(file)
    result = process(image_base64)
    return result
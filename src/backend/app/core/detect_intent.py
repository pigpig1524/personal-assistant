from app.config import Config
from app.core.llm.openai import create_chat
from app.core.llm.openai import client
from app.models.llm import CreateEventResponse, FindEmailResponse, IntentResponse
import json
from app.utils.utils import get_current_date
from app.services.firebtest import get_messages, add_message


PROMTPS = Config.PROMPT_CONFIG
PERSONA = Config.PROMPT_CONFIG.get('DETECT_INTENT')


class DetectIntentAgent:
    def __init__(self):
        pass

    def parse_info_by_intent(self, user_query, intent):
        sys_prompt = PROMTPS[intent]

        llm_response = client.chat.completions.create(
            model='gpt-4o-mini',
            messages=[
                {'role': 'system', 'content': sys_prompt},
                {'role': 'user', 'content': user_query}
            ],
            max_tokens=600
        )
        response = json.loads(llm_response.choices[0].message.content)
        return response

    
    def detect(self, user_query, user_id, lang_code="vi_VN"):
        sys_prompt = PROMTPS['DETECT_CUSTOM']
        sys_prompt = sys_prompt.replace(r'{today}', get_current_date())
        sys_prompt = sys_prompt.replace(r'{lang_code}', lang_code)

        history = get_messages(user_id)
        history = history[:8]

        conversation = [
            {'role': 'system', 'content': sys_prompt},
            # {'role': 'user', 'content': user_query}
        ]
        conversation.extend(history)
        conversation.append({'role': 'user', 'content': user_query})
        # resposne = create_chat(conversation)

        response = client.beta.chat.completions.parse(
            model='gpt-4o-mini',
            messages=conversation,
            response_format=IntentResponse
        )
        response = response.choices[0].message.parsed
        response_json = response.model_dump()
        # print(resposne)
        # response_json = json.loads(resposne)
        assistant_reply = response_json['response']

        add_message(user_id=user_id,
                    messages=[{'role': 'user', 'content': user_query},
                              {'role': 'assistant', 'content': assistant_reply}])

        return response_json

    def get_detail(self, context: dict, user_query: str):
        intent = context['intent']
        action = context['action']
        if intent == 'CHAT':
            detail = self.general_chat(user_query)
        elif intent == 'CALENDAR':
            if action == 'CREATE_EVENT':
                detail = self.parse_calendar_info(user_query)
        elif intent == 'EMAIL':
            if action == 'FIND_EMAIL':
                detail = self.find_email(user_query)
        return detail
    
    def general_chat(self, user_query: str):
        sys_prompt : str = PROMTPS['CHAT']
        sys_prompt = sys_prompt.replace(r'{today}', get_current_date())
        llm_response = client.chat.completions.create(
            model='gpt-4o-mini',
            messages=[
                {'role': 'system', 'content': sys_prompt},
                {'role': 'user', 'content': user_query}
            ],
            max_tokens=600
        )
        response = json.loads(llm_response.choices[0].message.content)
        print(response)
        return response
    
    def find_email(self, user_query):
        sys_prompt : str = PROMTPS['FIND_EMAIL']
        sys_prompt = sys_prompt.format(today=get_current_date())
        response = client.beta.chat.completions.parse(
            messages=[
                {'role': 'system', 'content': sys_prompt},
                {'role': 'user', 'content': user_query}
            ],
            model='gpt-4o-mini',
            response_format=FindEmailResponse
        )
        data = response.choices[0].message.parsed
        return data.model_dump()

    def parse_calendar_info(self, user_query):
        sys_prompt : str = PROMTPS['CREATE_EVENT']
        sys_prompt = sys_prompt.format(today=get_current_date())
        response = client.beta.chat.completions.parse(
            messages=[
                {'role': 'system', 'content': sys_prompt},
                {'role': 'user', 'content': user_query}
            ],
            model='gpt-4o-mini',
            response_format=CreateEventResponse
        )
        data = response.choices[0].message.parsed
        return data.model_dump()

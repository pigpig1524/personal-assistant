from app.core.llm.openai import client
from app.config import Config
from app.models.email import EmailRequest, EmailIntent
import re

PROMPTS = Config.PROMPT_CONFIG
TEMPLATES = Config.TEMPLATE_CONFIG
EMAIL_TYPE = ['Academic', 'Work', 'Promotion', 'Security', 'Other']

def detect_action(user_query: str):
    response = client.beta.chat.completions.parse(
        model='gpt-4o-mini',
        messages=[
            {'role': 'system', 'content': PROMPTS.get('EMAIL_DETECT_ACTION')},
            {'role': 'user', 'content': user_query}
        ],
        response_format=EmailIntent
    )
    message = response.choices[0].message.parsed
    return message


def postprocess_automatic_respond(respond: str):
    email_content = re.search(r"Subject:\s*(.*?)\s*Content:\s*(.*)", respond, re.DOTALL)
    if email_content:
        subject = email_content.group(1)
        content = email_content.group(2)
        return {'subject': subject, 'content': content}
    else:
        return {'subject': 'Failed to Process', 'content': 'Failed to Process'}

def process_auto_repy(context: EmailIntent, 
                      subject: str,
                      content: str):
    sys_prompt : str = PROMPTS.get('AUTOMATIC_RESPOND')
    template = TEMPLATES.get(context.template)
    sys_prompt = sys_prompt.format(subject=subject,
                                   content=content,
                                   template=template,
                                   note=context.note)
    
    response = client.chat.completions.create(
        model='gpt-4o-mini',
        messages=[{'role': 'user', 'content': sys_prompt}]
    )
    message = response.choices[0].message.content
    reuslt = postprocess_automatic_respond(message)
    return reuslt

def postprocess_classification(respond: str):
    text_lower = respond.lower()
    positions = {}
    
    # Check where each classification is located in the respond
    for classification in EMAIL_TYPE:
        pos = text_lower.find(classification.lower())
        if pos != -1:
            positions[classification] = pos

    # Pick the first one
    if positions:
        classification = min(positions, key=positions.get)
        return classification
    else:
        return "Other"  

def process_classify_email(email: EmailRequest):
    sys_prompt : str = PROMPTS.get('EMAIL_CLASSIFICATION')
    sys_prompt = sys_prompt.format(subject = email.subject,
                                   content = email.content,
                                   email_type = EMAIL_TYPE)
    response = client.chat.completions.create(
        model='gpt-4o-mini',
        messages=[{'role': 'user', 'content': sys_prompt}]
    )
    message = response.choices[0].message.content
    return postprocess_classification(message)


def process_summarization(email: EmailRequest):
    sys_prompt : str = PROMPTS.get('EMAIL_SUMMARIZATION')
    sys_prompt = sys_prompt.format(subject=email.subject,
                                   content=email.content)
    response = client.chat.completions.create(
        model='gpt-4o-mini',
        messages=[{'role': 'user', 'content': sys_prompt}]
    )
    message = response.choices[0].message.content
    return message

def main_process(data: EmailRequest):
    context = detect_action(data.user_query)
    if context.action == 'AUTOMATIC_RESPOND':
        response = process_auto_repy(context=context,
                                     subject=data.subject,
                                     content=data.content)
    elif context.action == 'EMAIL_CLASSIFICATION':
        response = process_classify_email(email=data)
    elif context.action == 'EMAIL_SUMMARIZATION':
        response = process_summarization(email=data)
    return {'intent': 'EMAIL',
            'action': context.action,
            'response': response}
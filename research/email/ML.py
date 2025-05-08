from openai import OpenAI
import re

class ML:
    def __init__(
        self,
        client_type="openai",
        model="solar-pro",
        base_url="https://api.upstage.ai/v1/solar",
        api_key=None,
        summarization_length_ratio=0.1,
        summarization_max_length_min=50,
        ml_temperature=0.7,
        classifications=['Academic', 'Work', 'Promotion', 'Security', 'Other']
    ):
        if client_type == "openai":
            # System
            self.client = OpenAI(
                base_url=base_url,
                api_key=api_key,
            )
            self.client_type = client_type
            self.model = model
            
            # Prompt
            with open("data/prompt_classification.txt", "r") as f:
                self.prompt_classification = f.read()
            with open("data/prompt_summarization.txt", "r") as f:
                self.prompt_summarization = f.read()
            with open("data/prompt_automatic_respond.txt", "r") as f:
                self.prompt_automatic_respond = f.read()
                
            # Params
            self.summarization_length_ratio = summarization_length_ratio
            self.summarization_max_length_min = summarization_max_length_min
            self.ml_temperature = ml_temperature
            self.classifications = classifications
        else:
            raise ValueError("client_type not implemented")
        
    def get_respond(self, 
                    prompt: str,
                    temperature=0,
                    max_tokens=float('inf')):
        params = {
            "model": self.model,
            "messages": [
                {
                    "role": "user",
                    "content": prompt,
                }
            ],
            "temperature": temperature
        }
        if max_tokens != float('inf'):
            params["max_tokens"] = int(max_tokens)
        response = self.client.chat.completions.create(**params)
        return response.choices[0].message.content

    def postprocess_classification(self, respond: str):
        text_lower = respond.lower()
        positions = {}
        
        # Check where each classification is located in the respond
        for classification in self.classifications:
            pos = text_lower.find(classification.lower())
            if pos != -1:
                positions[classification] = pos

        # Pick the first one
        if positions:
            classification = min(positions, key=positions.get)
            return classification
        else:
            return "Other"  
    
    def postprocess_automatic_respond(self, respond: str):
        email_content = re.search(r"Subject:\s*(.*?)\s*Content:\s*(.*)", respond, re.DOTALL)
        if email_content:
            subject = email_content.group(1)
            content = email_content.group(2)
            return {'subject': subject, 'content': content}
        else:
            return {'subject': 'Failed to Process', 'content': 'Failed to Process'}
        
    def get_email_summarization(self, subject, content):
        content_length = len(content)
        
        prompt = self.prompt_summarization.format(
            subject=subject, 
            content=content)
        summarization = self.get_respond(
            prompt=prompt, 
            temperature=self.ml_temperature,
            max_tokens=min(content_length * self.summarization_length_ratio, self.summarization_max_length_min))
        return summarization
    
    def get_email_classification(self, subject, content):
        prompt = self.prompt_classification.format(
            subject=subject, 
            content=content, 
            classifications=str(self.classifications))
        respond = self.get_respond(
            prompt=prompt,
            temperature=self.ml_temperature,
        )
        return self.postprocess_classification(respond)
    
    def get_email_automatic_respond(self, subject, content, template, note=""):
        prompt = self.prompt_automatic_respond.format(
            subject=subject,
            content=content,
            template=template,
            note=note,
        )
        respond = self.get_respond(
            prompt=prompt,
            temperature=self.ml_temperature,
        )
        return self.postprocess_automatic_respond(respond)
    
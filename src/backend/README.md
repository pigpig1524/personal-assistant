# [LOTUS - IPA] Backend Documentation

First of all, here are some important notes:
- The command, bash script is written for Linux OS
- You can find the sample env file in `backend/.env.sample`

Key is now copy to image when build Docker. This action is not good. But, in this phase, it's OK 

Dcoker ignore file wiil be update later when final deployment is released.


## Configure secrets
Use your own secrets, or the shared one. Place it at `backend/.env`

The required secrets are:
- `OPENAI_API_KEY` (string): The API key of OpenAI LLM models
- `GCP_PROJECT_ID` (string): The cloud project ID on GCP

## Local testing

### Prepare Python virtual environment 
You can give it another name. However, `venv` is recommended due to gitignore matching

```bash
python3 -m venv venv
source venv/bin/activate
```
### Install packages

```bash
cd backend
pip intstall -r requirements.txt
```

### Run the server
```bash
python3 main.py
```

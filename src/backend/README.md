# [LOTUS - IPA] Backend Documentation

First of all, here are some important notes:
- The command, bash script is written for Linux OS
- You can find the sample env file in `backend/.env.sample`

Key is now copy to image when build Docker. This action is not good. But, in this phase, it's OK 

Dcoker ignore file wiil be update later when final deployment is released


## Setup environment variables
Place it at `backend/.env`

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

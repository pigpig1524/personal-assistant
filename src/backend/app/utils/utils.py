import yaml
import json
from easydict import EasyDict as edict
import platform
# from app.db.models import Position, PositionOut

def load_yaml(file_path: str):
    """parse YAML config to EasyDict format

    Args:
        config_path (str): path to config YAML file

    Returns:
        EasyDict: config dictionary in easydict format
    """
    try:
        with open(file_path, 'r', encoding="utf-8") as f:
            config = yaml.safe_load(f)
        return edict(config)

    except Exception as err:
        print('config file cannot be read.')
        print(err)
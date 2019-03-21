import logging
import sys
from logging import INFO, WARNING, ERROR, DEBUG


def get_logger(name):
    logger = logging.getLogger(name)
    logger.setLevel(INFO)
    handler = logging.StreamHandler(stream=sys.stdout)
    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    handler.setFormatter(formatter)
    logger.addHandler(handler)
    logger.propagate = False
    return logger

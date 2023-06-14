from .logger import logging, Formatter, log_level, log


def store_logs(filepath: str):
    handler = logging.FileHandler(f"{filepath}.log")
    handler.setLevel(log_level)
    handler.setFormatter(Formatter())

    log.addHandler(handler)

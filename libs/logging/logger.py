import logging
import os

from .formatter import Formatter
from .constants import log_levels

log_level = log_levels[os.environ.get("LOGGING_LOG_LEVEL", "info").lower()]
should_colorize = os.environ.get("LOGGING_COLORIZE", "true").lower() == "true"

log = logging.getLogger(os.environ.get("APP", "default"))
log.setLevel(log_level)

log_handler = logging.StreamHandler()
log_handler.setLevel(log_level)
log_handler.setFormatter(Formatter(colorize=should_colorize))

log.addHandler(log_handler)

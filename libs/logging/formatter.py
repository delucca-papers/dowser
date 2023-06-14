import logging


class Formatter(logging.Formatter):
    template = (
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s (%(filename)s:%(lineno)d)"
    )
    colorize = False
    grey = "\x1b[38;20m"
    yellow = "\x1b[33;20m"
    red = "\x1b[31;20m"
    bold_red = "\x1b[31;1m"
    reset = "\x1b[0m"

    FORMATS = {
        logging.DEBUG: grey + template + reset,
        logging.INFO: grey + template + reset,
        logging.WARNING: yellow + template + reset,
        logging.ERROR: red + template + reset,
        logging.CRITICAL: bold_red + template + reset,
    }

    def __init__(self, colorize: bool = False):
        super().__init__(self.template)
        self.colorize = colorize

    def format(self, record: logging.LogRecord):
        template = self.FORMATS.get(record.levelno) if self.colorize else self.template
        formatter = logging.Formatter(template)

        return formatter.format(record)

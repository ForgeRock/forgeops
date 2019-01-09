import logging


class LogUtil(object):
    """
    Logging utilities.
    Methods:
        get_root_logger: returns the root logger for general use.
    """
    _format = "%(asctime)s %(filename)-10s %(levelname)-8s: %(message)s"
    _handlers = []

    @staticmethod
    def get_root_logger():
        return logging.getLogger("openshift-scaling")

    @classmethod
    def set_log_handler(cls, logfile):
        """
        Set main log file location.
        Parameters:
            logfile (str) : file path
        Returns:
            True (bool)
        """
        logger = cls.get_root_logger()
        logger.setLevel(logging.DEBUG)

        fh = logging.FileHandler(logfile)
        fh.setFormatter(logging.Formatter(cls._format, "%Y-%m-%dT%T%Z"))
        fh.setLevel(logging.INFO)

        logger.addHandler(fh)
        return True

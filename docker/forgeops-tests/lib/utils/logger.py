# Lib imports
import logging
import os
LOGGER = logging.getLogger(__name__)
ch = logging.StreamHandler()
formatter = logging.Formatter('%(message)s')
ch.setFormatter(formatter)
LOGGER.addHandler(ch)
LOGGER.setLevel(logging.DEBUG)

# Optional file handler
# fl = logging.FileHandler(os.path.abspath('tests.log', "w+")
# fl.setLevel(logging.INFO)
# fl.setFormatter(formatter)
# LOGGER.addHandler(fl)

info = LOGGER.info
error = LOGGER.error
debug = LOGGER.debug
warning = LOGGER.warning


def test_step(message):
    info('*** %s ***' % message)

# Lib imports
import logging

logging.basicConfig(format='%(message)s')
LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(logging.DEBUG)

info = LOGGER.info
error = LOGGER.error
debug = LOGGER.debug
warning = LOGGER.warning


def test_step(message):
    info('*** %s ***' % message)

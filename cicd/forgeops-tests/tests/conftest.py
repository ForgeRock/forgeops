# Lib imports
import os


def pytest_configure(config):
    if 'TESTS_NAMESPACE' in os.environ:
        config._metadata['TESTS_NAMESPACE'] = os.environ['TESTS_NAMESPACE']
    else:
        config._metadata['TESTS_NAMESPACE'] = 'smoke'
    if 'TESTS_DOMAIN' in os.environ:
        config._metadata['TESTS_DOMAIN'] = os.environ['TESTS_DOMAIN']
    else:
        config._metadata['TESTS_DOMAIN'] =  'forgeops.com'

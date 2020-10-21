import os
import sys
import logging

from flask import Flask
import requests

from pruner import registry, disk

log_level = os.environ.get('LOG_LEVEL', 'INFO')
logging.basicConfig(stream=sys.stdout, level=log_level)
log = logging.getLogger('pruner')
log.info('initializing pruner')

app = Flask('pruner')

@app.route('/registry', methods=['POST'])
def registry_route():
    try:
        log.info('prune registry started')
        registry.prune_registry()
    except requests.HTTPError as e:
        log.error(f'prune registry error: {e}')
        return e.response.reason, e.response.status_code
    except Exception as e:
        log.error(f'prune registry exception: {e}')
        return f'Bad Request: {e}', 400
    # Flush the stdout to avoid log buffering.
    log.info('prune registry success')
    sys.stdout.flush()
    return ('', 204)


@app.route('/disks', methods=['POST'])
def disks_route():
    try:
        log.info('prune disk started')
        if not disk.prune_disks():
            log.error('prune disks failed')
            return (f'Conflict: Errors Deleting', 409)
        return ('Completed', 204)
    except Exception as e:
        log.error(f'pruning exception: {e}')
        return (f'Bad Request: {e}', 400)
    log.info('prune disks success')
    sys.stdout.flush()
    return ('', 204)

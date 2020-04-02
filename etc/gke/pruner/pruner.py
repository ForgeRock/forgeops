import base64
import os
import sys
import datetime
import logging
import re

import google.auth
from google.auth.transport.requests import AuthorizedSession
from flask import Flask
import requests

log_level = os.environ.get('LOG_LEVEL', 'INFO')
logging.basicConfig(stream=sys.stdout, level=log_level)
log = logging.getLogger('gcr-pruner')
log.info('initializing gcr pruner')

# dont actually delete
DRY_RUN = bool(int(os.environ.get('GCR_PRUNE_DRY_RUN', 0)))
# export MAX_UPDATE_AGE=DAYS maximum age of a digest
# (delete if currrent_time - last_update > MAX_UPDATE_AGE)
MAX_AGE = datetime.timedelta(int(os.environ.get('MAX_UPDATE_AGE', 30)))

REGISTRY_BASE = 'https://gcr.io/v2'
try:
    credentials, project = google.auth.default(scopes=['https://www.googleapis.com/auth/cloud-platform'])
    authed_session = AuthorizedSession(credentials)
    app = Flask(__name__)
except Exception as e:
    log.error(e)
    sys.stdout.flush()
# iterable of regex strings to exclude
_black_list_repos = [
   # all base images
   # r'^engineering-devops\/(?:\w*-base$)',
   # r'^engineering-devops\/(am|ds|(?:ds-\w*)|idm|amster)$',
   ]

EXCLUDE = [ re.compile(i) for i in _black_list_repos ]

def repo_tags(repo):
    url = f'{REGISTRY_BASE}/{repo}/tags/list'
    response = authed_session.get(url)
    response.raise_for_status()
    return response.json().get('manifest')

def filter_digests(digests, max_recent_update_age):
    filtered = []
    for digest_id, digest_meta in digests.items():
        tagless = len(digest_meta['tag']) == 0
        last_update = datetime.datetime.utcfromtimestamp(
            int(digest_meta['timeUploadedMs']) / 1000.0000)
        stale =  datetime.datetime.now() - last_update > MAX_AGE
        log.debug(f'{digest_id} {last_update}')
        if tagless and stale:
            filtered.append(digest_id)
    num_digests = len(filtered)
    log.info(f'found {num_digests} to prune')
    return filtered

def registry_repos(exclude_images):
    response = authed_session.get(f'{REGISTRY_BASE}/_catalog')
    response.raise_for_status()
    repos = response.json()['repositories']
    for repo in repos:
        if not any(i.search(repo) for i in exclude_images):
            yield repo


def prune_manifests(repo, digest_ids, dry_run=DRY_RUN):
    for digest_id in digest_ids:
        try:
            url = f'{REGISTRY_BASE}/{repo}/manifests/{digest_id}'
            if dry_run:
                log.info(f'dry run: DELETE {url}')
            else:
                response = authed_session.delete(url, timeout=5)
                response.raise_for_status()
                log.info(f'DELETE {repo} {digest_id}')
        except requests.exceptions.Timeout as e:
            log.error(f'error removing {repo} manifest {digest_id}')

def prune_registry(dry_run=DRY_RUN):
    log.info(f'is dry run {dry_run}')
    for repo in registry_repos(EXCLUDE):
        log.info(f'pruning {repo}')
        digests_to_remove = filter_digests(repo_tags(repo), 14)
        prune_manifests(repo, digests_to_remove, dry_run=dry_run)

@app.route('/', methods=['POST'])
def index():
    try:
        prune_registry()
    except requests.HTTPError as e:
        log.error(e)
        return e.response.reason, e.response.status_code
    except Exception as e:
        log.error(e)
        return f'Bad Request: {e}', 400
    # Flush the stdout to avoid log buffering.
    sys.stdout.flush()
    return ('', 204)

if __name__ == '__main__':
    prune_registry()

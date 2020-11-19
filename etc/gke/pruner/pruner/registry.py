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
ENGINEERING_DEVOPS_MAX_AGE = datetime.timedelta(int(os.environ.get('MAX_UPDATE_AGE', 30)))
ENGINEERING_PIT_MAX_AGE = datetime.timedelta(int(os.environ.get('ENGINEERINGPIT_MAX_UPDATE_AGE', 30)))
FORGEOPS_PUBLIC_MAX_AGE = datetime.timedelta(int(os.environ.get('FORGEOPS_PUBLIC_AGE', 365)))
FORGEROCK_IO_MAX_AGE = datetime.timedelta(int(os.environ.get('FORGEROCK_IO_MAX_UPDATE_AGE', 90)))
FORGEROCK_IO_PULL_REQUEST_MAX_AGE = datetime.timedelta(int(os.environ.get('FORGEROCK_IO_MAX_UPDATE_AGE', 30)))

REGISTRY_BASE = 'https://gcr.io/v2'

try:
    credentials, project = google.auth.default(scopes=['https://www.googleapis.com/auth/cloud-platform'])
    authed_session = AuthorizedSession(credentials)
except Exception as e:
    log.error(e)
    sys.stdout.flush()

GIT_SHA1_PATTERN = re.compile(r'^[0-9a-f]{7,40}$')

# helpers

def repo_tags(repo):
    url = f'{REGISTRY_BASE}/{repo}/tags/list'
    response = authed_session.get(url)
    response.raise_for_status()
    return response.json().get('manifest')

def image_is_stale(image_digest_id, image_digest_meta, max_recent_update_age):
    last_update = datetime.datetime.utcfromtimestamp(
        int(image_digest_meta['timeUploadedMs']) / 1000.0000)
    log.debug(f'{image_digest_id} {last_update}')
    return datetime.datetime.now() - last_update > max_recent_update_age

def image_is_untagged(image_digest_meta):
    return len(image_digest_meta['tag']) == 0

def image_is_only_tagged_with_development_versions(image_digest_meta):
    """Determine if image is only tagged with development versions, e.g. 7.0.0-37c45b4d11984014498cb35e3925d0a3e0c053ff
    """
    for tag in image_digest_meta['tag']:
        if not is_development_tag(tag):
            return False
    return True

def is_development_tag(tag):
    """A development tag is one ending with a hyphen followed by a git SHA1
    """
    if '-' not in tag:
        return False
    tag_suffix = tag.split('-')[-1]
    return GIT_SHA1_PATTERN.search(tag_suffix) is not None

def is_pr_repo(repo):
    """Images pushed from a PR can be deleted more frequently than other images.
    """
    image_promotion_level = repo.split('/')[-1]
    return image_promotion_level == 'pull-requests'

def filter_forgeops_public_digests(repo, digests):
    """Returns a dictionary of digests to prune; keys are the digests, values are that digest's tags
    """
    return filter_digests_by_age(repo, digests, FORGEOPS_PUBLIC_MAX_AGE)

def filter_engineeringpit_digests(repo, digests):
    """Returns a dictionary of digests to prune; keys are the digests, values are that digest's tags
    """
    return filter_digests_by_age(repo, digests, ENGINEERING_PIT_MAX_AGE)

def filter_digests_by_age(repo, digests, age):
    """Returns a dictionary of digests to prune; keys are the digests, values are that digest's tags
    """
    filtered = {}
    for digest_id, digest_meta in digests.items():
        stale = image_is_stale(digest_id, digest_meta, age)
        if stale:
            filtered[digest_id] = digest_meta['tag']
    num_digests = len(filtered)
    log.info(f'found {num_digests} to prune')
    return filtered

def filter_engineering_devops_digests(repo, digests):
    """Returns a dictionary of digests to prune; keys are the digests, values are that digest's tags
    """
    return filter_digests_by_age(repo, digests, ENGINEERING_DEVOPS_MAX_AGE)

def filter_forgerock_io_digests(repo, digests):
    """Returns a dictionary of digests to prune; keys are the digests, values are that digest's tags
    """
    filtered = {}
    if is_pr_repo(repo):
        for digest_id, digest_meta in digests.items():
            if 'fraas-production' not in digest_meta['tag']:  # NEVER delete anything tagged with 'fraas-production'
                if image_is_stale(digest_id, digest_meta, FORGEROCK_IO_PULL_REQUEST_MAX_AGE):
                    filtered[digest_id] = digest_meta['tag']
    else:
        for digest_id, digest_meta in digests.items():
            if 'fraas-production' not in digest_meta['tag']:  # NEVER delete anything tagged with 'fraas-production'
                tagless = image_is_untagged(digest_meta)
                development_only = image_is_only_tagged_with_development_versions(digest_meta)
                stale = image_is_stale(digest_id, digest_meta, FORGEROCK_IO_MAX_AGE)
                if (tagless or development_only) and stale:
                    filtered[digest_id] = digest_meta['tag']
    num_digests = len(filtered)
    log.info(f'found {num_digests} to prune')
    return filtered

filter_route = (
    # specific rules first 
    (r'^engineering-devops\/smoketest$', None),
    (r'^engineering-devops\/skaffold$', None),
    (r'^engineering-devops\/ci.*', None),
    (r'^engineeringpit/lodestar-images/*', filter_engineeringpit_digests, ),

    # top level inclusions
    (r'^engineering-devops/*', filter_engineering_devops_digests,),
    (r'^forgerock-io/*', filter_forgerock_io_digests, ),
    (r'^forgeops-public/*', filter_forgeops_public_digests, ),
)
FILTER_ROUTES = [ (re.compile(i[0]), i[1]) for i in filter_route]

def registry_repos(exclude_images):
    """search registry for repo routes for first match yielding the route and filter function
    """
    response = authed_session.get(f'{REGISTRY_BASE}/_catalog')
    response.raise_for_status()
    repos = response.json()['repositories']
    for repo in repos:
        for regex, filter_method in exclude_images:
            match = regex.search(repo)
            if not match:
                continue
            elif filter_method:
                yield repo, filter_method
            # if we got any kind of match, move on to the next repo
            break

def delete_manifest(repo, manifest, dry_run=DRY_RUN):
    """Delete a single manifest; can be used to delete images and tags.
    """
    try:
        url = f'{REGISTRY_BASE}/{repo}/manifests/{manifest}'
        if dry_run:
            log.info(f'dry run: DELETE {url}')
        else:
            response = authed_session.delete(url, timeout=5)
            response.raise_for_status()
            log.info(f'DELETE {repo} {manifest}')
    except requests.exceptions.Timeout as e:
        log.error(f'error removing {repo} manifest {manifest}')

def prune_manifests(repo, digest_ids, dry_run=DRY_RUN):
    for digest_id, tags in digest_ids.items():
        # in GCR, an image's tags must all be deleted before the image can be deleted
        for tag in tags:
            delete_manifest(repo, tag, dry_run)
        delete_manifest(repo, digest_id, dry_run)

def prune_registry(dry_run=DRY_RUN):
    log.info(f'is dry run {dry_run}')
    for repo , filter_digests in registry_repos(FILTER_ROUTES):
        log.info(f'pruning {repo}')
        digests_to_remove = filter_digests(repo, repo_tags(repo))
        prune_manifests(repo, digests_to_remove, dry_run=dry_run)
        log.info(f'pruned repo: {repo}')

if __name__ == '__main__':
    prune_registry()

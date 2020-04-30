#!/usr/bin/env python3

import os
import subprocess
import logging
import pprint
import re
import sys

import google.auth
from google.auth.transport.requests import AuthorizedSession

usage_str = """
usage: ./backup.py source_registry target_registry

Back up production Docker images in a separate registry.

Running this script will leave you logged into 'gcloud' as the account in the
file referenced by the GOOGLE_APPLICATION_CREDENTIALS environment variable.
"""

log_level = os.environ.get('LOG_LEVEL', 'INFO')
logging.basicConfig(stream=sys.stdout, level=log_level)
log = logging.getLogger('gcr-backup')
log.info('initializing gcr backup')

DRY_RUN = bool(int(os.environ.get('GCR_BACKUP_DRY_RUN', 0)))

REGISTRY_BASE = 'https://gcr.io/v2'
REGISTRY_ROOT = 'gcr.io'
try:
    credentials, project = google.auth.default(scopes=['https://www.googleapis.com/auth/cloud-platform'])
    authed_session = AuthorizedSession(credentials)
except Exception as e:
    log.error(e)
    sys.stdout.flush()

# Permits the following pattern types: a.b.c / a.b.c-d / a.b.c.d / a.b.c.d-e
FORGEROCK_RELEASE_PATTERN = re.compile(r'^((0|[1-9]\d*)\.){2,3}(0|[1-9]\d*)(-(0|[1-9]\d{0,4}))?$')


def is_production_tag(tag):
    if tag.startswith('IC'):
        tag = re.sub(r'^IC', '', tag)
    return tag == 'fraas-production' or FORGEROCK_RELEASE_PATTERN.search(tag)


def copy_image(tagged_image, source_registry, target_registry, dry_run=DRY_RUN):
    if not tagged_image.startswith(source_registry):
        raise ValueError(f"Re-tagging {tagged_image} - image must be in the '{source_registry}' registry")
    retagged_image = re.sub(rf'^{source_registry}', target_registry, tagged_image)
    log.info(f'gcloud container images add-tag {REGISTRY_ROOT}/{tagged_image} {REGISTRY_ROOT}/{retagged_image}')
    if not dry_run:
        subprocess.run([
            'gcloud',
            'container',
            'images',
            'add-tag',
            f'{REGISTRY_ROOT}/{tagged_image}',
            f'{REGISTRY_ROOT}/{retagged_image}',
            '--quiet'
        ]).check_returncode()


def production_images(repository):
    """Retrieve production images from the specified repository"""
    log.info(f'Searching for production images in {repository}...')
    response = authed_session.get(f'{REGISTRY_BASE}/{repository}/tags/list')
    response.raise_for_status()
    response_json = response.json()
    for tag in response_json['tags']:
        if is_production_tag(tag):
            yield f'{repository}:{tag}'
    # recurse through child repositories
    for child_repository in response_json['child']:
        yield from production_images(f'{repository}/{child_repository}')


def backup_images(source_registry, target_registry, dry_run=DRY_RUN):
    log.info(f'backing up production images in {source_registry} to {target_registry}')
    log.info(f'is dry run {dry_run}')

    images = list(production_images(source_registry))
    for image in images:
        copy_image(image, source_registry, target_registry, dry_run)
    log.info(f"Backed up the following images to '{target_registry}':\n{pprint.pformat(images)}")


def activate_service_account():
    """Activate Google SA if one is provided, else use the default account when launching gcloud commands."""
    credentials_file = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')
    if credentials_file:
        subprocess.run([
            'gcloud',
            'auth',
            'activate-service-account',
            credentials.service_account_email,
            f'--key-file={credentials_file}'
        ]).check_returncode()


def print_account_warning():
    print(f"\nCaution, you are still logged into gcloud as {credentials.service_account_email}\n")
    print('To view your gcloud accounts, run:\n\t$ gcloud auth list\n')
    print('To set the active account, run:\n\t$ gcloud config set account `ACCOUNT`\n')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print(usage_str)
        sys.exit(1)

    _, source_registry, target_registry = sys.argv
    activate_service_account()
    backup_images(source_registry, target_registry)
    print_account_warning()

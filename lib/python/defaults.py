""" Global defaults """
import sys
from shutil import which

ALT_RELEASES = ['dev', 'latest']
FORGEOPS_PUBLIC_URL = 'us-docker.pkg.dev/forgeops-public'
BASE_REPO_DEV = "gcr.io/forgerock-io"
BASE_REPO_DEF = f"{FORGEOPS_PUBLIC_URL}/images-base"
DEPLOY_REPO_DEF = f"{FORGEOPS_PUBLIC_URL}/images"
RELEASES_SRC_DEF = 'https://releases.forgeops.com'
SNAPSHOT_ROLE_NAME = 'ds-snapshot'
SNAPSHOT_SERVICE_ACCOUNT = 'ds-snapshot'

KUBECTL = which('kubectl')
if not KUBECTL:
    print("ERROR!! kubectl missing from PATH. Exiting.")
    sys.exit(1)
HELM_CMD = which('helm')

# Helm defaults
HELM_CHART_NAME_DEF = "identity-platform"
HELM_CHART_REPO_DEF = "https://ForgeRock.github.io/forgeops"

# This seems like it could be a list. However, these component names can be
# overridden in the release JSON files. If a release has a custom component name,
# this map get updated with that custom name.
BASE_IMAGE_NAMES = {
    'am': 'am',
    'am-custom': 'am-custom',
    'am-config-upgrader': 'am-config-upgrader',
    'amster': 'amster',
    'ds': 'ds',
    'idm': 'idm',
    'idm-admin-ui': 'idm-admin-ui',
    'idm-custom': 'idm-custom',
    'ig': 'ig',
    'ig-custom': 'ig-custom',
    'admin-ui': 'admin-ui',
    'end-user-ui': 'end-user-ui',
    'login-ui': 'login-ui',
}

ENV_COMPONENTS_VALID = [
    'am',
    'amster',
    'ds',
    'ds-cts',
    'ds-idrepo',
    'idm',
    'ig',
    'ldif-importer',
    'admin-ui',
    'end-user-ui',
    'login-ui'
]

HELM_CHART_DEFAULTS = {
    'name': HELM_CHART_NAME_DEF,
    'repo': HELM_CHART_REPO_DEF,
}

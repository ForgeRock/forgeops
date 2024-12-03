""" Global defaults """

ALT_RELEASES = ['dev']
FORGEOPS_PUBLIC_URL = 'us-docker.pkg.dev/forgeops-public'
BASE_REPO_DEV = "gcr.io/forgerock-io"
BASE_REPO_DEF = f"{FORGEOPS_PUBLIC_URL}/images-base"
DEPLOY_REPO_DEF = f"{FORGEOPS_PUBLIC_URL}/images"
RELEASES_SRC_DEF = 'http://releases.forgeops.com'

# This seems like it could be a list. However, these component names can be
# overridden in the release JSON files. If a release has a custom component name,
# this map get updated with that custom name.
BASE_IMAGE_NAMES = {
    'am': 'am',
    'am-config-upgrader': 'am-config-upgrader',
    'amster': 'amster',
    'ds': 'ds',
    'idm': 'idm',
    'ig': 'ig',
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

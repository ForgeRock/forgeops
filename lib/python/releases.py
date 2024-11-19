"""Functions to help read, process, and select release image tags"""

from copy import copy
from copy import deepcopy
import os
import json
from pathlib import Path, PurePath
import re
import sys
import site
from urllib.request import urlopen
from urllib.error import URLError, HTTPError

file_name = Path(__file__)
current_file_path = file_name.parent.resolve()
root_path = [parent_path for parent_path in current_file_path.parents if (parent_path / 'README.md').exists()][0]
dependencies_dir = os.path.join(root_path, 'lib', 'dependencies')
# Insert lib folders to python path
sys.path.insert(0, str(root_path))
sys.path.insert(1, str(dependencies_dir) + site.USER_SITE.replace(site.USER_BASE, ''))

import lib.python.utils as utils

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
    'amster': 'amster',
    'ds': 'ds',
    'idm': 'idm',
    'ig': 'ig',
    'admin-ui': 'admin-ui',
    'end-user-ui': 'end-user-ui',
    'login-ui': 'login-ui',
}


def get_releases(releases_src, components):
    """
    Get the list of available releases
    releases_src: string (absolute path, path releative to root_path, or http URL)
    components: list (components to get release info for)
    """
    releases = {}
    do_http = False
    if not isinstance(releases_src, PurePath):
        if releases_src.startswith('http'):
            do_http = True
        else:
            releases_src = Path(releases_src)
    for c in components:
        data = {}
        json_file = f"{c}.json"
        if do_http:
            url = f"{releases_src}/{json_file}"
            try:
                with urlopen(f"{url}") as url:
                    data = json.load(url)
            except HTTPError as e:
                print(f"Skipping {url}. HTTP Error: {e.code}")
                continue
            except URLError as e:
                print(f"Skipping {url}. URL Error: {e.reason}")
                continue
        else:
            json_file_path = releases_src / json_file
            if json_file_path.is_file():
                with open(releases_src / f"{json_file}") as f:
                    data = json.load(f)
            else:
                print(f"Skipping {json_file_path} (No such file)")
                continue
        releases[c] = data['releases']
    return releases


def parse_release_str(rel_str, debug=False):
    """
    Split the release string, and setup a map of different release strings.
    rel_str: string (eg: 7.5.1)
    debug: boolean
    """

    release = {
        'major': 0,
        'minor': 0,
        'patch': 0,
    }

    if debug:
        print(f"rel_str={rel_str}")

    if rel_str in ALT_RELEASES:
        release['maj_min'] = rel_str
        release['full'] = rel_str
    else:
        if rel_str.count('.') == 0:
            release['major'] = rel_str
        elif rel_str.count('.') == 1:
            release['major'] = int(rel_str.split('.')[0])
            release['minor'] = int(rel_str.split('.')[1])
        elif rel_str.count('.') == 2:
            release['major'] = int(rel_str.split('.')[0])
            release['minor'] = int(rel_str.split('.')[1])
            release['patch'] = int(rel_str.split('.')[2])
        release['major'] = int(release['major'])
        release['major'] = release['major']
        release['maj_min'] = f"{release['major']}.{release['minor']}"
        release['full'] = f"{release['maj_min']}.{release['patch']}"

    return release


def select_tag(component, releases, release, image_names, tag=None):
    """
    Select the best tag based on the component, release, and/or tag.
    component: string (eg: am)
    releases: dict (generated by get_releases())
    release: dict (generated by parse_release_str())
    image_names: dict (BASE_IMAGE_NAMES)

    image_names is a mapping of standard component names. The BASE_IMAGE_NAMES
    dictionary has the standard names, and it can be updated by this function
    if the selected release has defined 'component_name' in the component JSON
    file.
    """

    major = release['major']
    minor = release['minor']
    patch = release['patch']
    full = release['full']
    maj_min = release['maj_min']
    selected_tag = None

    if 'target' not in release.keys():
        release['target'] = full
    target = release['target']

    if maj_min in releases[component].keys():
        if 'component_name' in releases[component][maj_min]:
            image_names[component] = releases[component][maj_min]['component_name']
        if full in releases[component][maj_min].keys():
            if tag in releases[component][maj_min][full]['tags']:
                selected_tag = tag
            else:
                selected_tag = releases[component][maj_min][full]['tags'][-1]
        elif patch > 0:
            patch_new = patch - 1
            full_new = f"{maj_min}.{patch_new}"
            release_new = deepcopy(release)
            release_new['patch'] = patch_new
            release_new['full'] = full_new
            selected_tag, image_names = select_tag(component, releases, release_new, image_names, tag)
    else:
        utils.exit_msg(f"Invalid release {target}. Only supports releases 7.4+.")

    return selected_tag, image_names


def set_image(image_name, tag, repo=None):
    """
    Create a dictionary entry for a component image
    image_name: string (Should be derived from image_names map)
    tag: string
    repo: string
    """
    data = { 'image': {} }
    data['image']['repository'] = f"{repo}/{image_name}" if repo else image_name
    if tag:
        data['image']['tag'] = tag
    return data

def select_image_repo(release, image_repo=None, env=None):
    """
    Select an image repo to use
    release: dict (generated by parse_release_str())
    image_repo: string
    env: string (environment name)
    """

    base_repo = copy(BASE_REPO_DEF)
    deploy_repo = copy(DEPLOY_REPO_DEF)
    if os.getenv('BASE_REPO') is not None:
        base_repo = os.getenv('BASE_REPO')
    if os.getenv('DEPLOY_REPO') is not None:
        deploy_repo = os.getenv('DEPLOY_REPO')

    repo = copy(deploy_repo)
    if release and not env:
        repo = copy(base_repo)
        if release == 'dev':
            repo = copy(base_repo_dev)

    if image_repo:
        if image_repo == 'base':
            repo = base_repo
        elif image_repo == 'base-default':
            repo = copy(BASE_REPO_DEF)
        elif image_repo == 'deploy':
            repo = deploy_repo
        elif image_repo == 'deploy-default':
            repo = copy(DEPLOY_REPO_DEF)
        elif image_repo == 'dev':
            repo = copy(base_repo_dev)
        elif image_repo.lower() == 'none':
            repo = None
        else:
            repo = image_repo

    return repo

def get_release_from_tag(tag, debug=False):
    """
    Try and determine a release version from the provided tag
    tag: string
    debug: boolean
    """

    if debug:
        print(f"get_release_from_tag(): tag={tag}")
    result = None
    if tag is not None:
        result = tag
        if '.' in tag:
            result = re.sub(".*([0-9].[0-9].[0-9]).*", r"\1", tag)
    return result

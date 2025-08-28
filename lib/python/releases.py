"""Functions to help read, process, and select release image tags"""

from copy import copy
from copy import deepcopy
import os
import json
from packaging.version import Version
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
import lib.python.defaults as defaults

ALT_RELEASES = defaults.ALT_RELEASES
FORGEOPS_PUBLIC_URL = defaults.FORGEOPS_PUBLIC_URL
BASE_REPO_DEV = defaults.BASE_REPO_DEV
BASE_REPO_DEF = defaults.BASE_REPO_DEF
DEPLOY_REPO_DEF = defaults.DEPLOY_REPO_DEF
RELEASES_SRC_DEF = defaults.RELEASES_SRC_DEF
BASE_IMAGE_NAMES = defaults.BASE_IMAGE_NAMES


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

    release = None

    if debug:
        print(f"rel_str={rel_str}")

    if rel_str in ALT_RELEASES:
        release = rel_str
    else:
        try:
            release = Version(rel_str)
        except ValueError:
            utils.exit_msg(f'Error : unknown "{rel_str}" release. The release should be like integer.integer.integer (eg 7.5.0)')

    return release


def get_available_release(requested_release, component_releases, search='backward', debug=False):
    """
    Return a sorted list of available releases from a given release and dictionary of all releases.
    """
    selected_release = None
    if isinstance(requested_release, str):
        if requested_release == 'latest':
            major_releases = list(component_releases.keys())
            for ar in ALT_RELEASES:
                if ar in major_releases:
                    major_releases.remove(ar)
            if 'scan' in major_releases:
                major_releases.remove('scan')
            major_releases.sort()
            maj_min = major_releases[-1]
            minor_releases = list(component_releases[maj_min].keys())
            if 'scan' in minor_releases:
                minor_releases.remove('scan')
            minor_releases.sort()
            selected_release = Version(minor_releases[-1])
        elif requested_release in ALT_RELEASES:
            selected_release = requested_release
        else:
            utils.exit_msg(f"Unknown release ({requested_release}). Use forgeops info --list-releases to see valid releases")
    else:
        minor_releases = []
        maj_min = f"{requested_release.major}.{requested_release.minor}"
        if maj_min in component_releases:
            for minor_release in component_releases[maj_min].keys():
                if (minor_release in ALT_RELEASES) or (minor_release == 'scan'):
                    continue
                minor_releases.append(Version(minor_release))
        minor_releases.sort()
        if requested_release in minor_releases:
            if debug:
                print(f"Requested release ({requested_release}) valid")
            selected_release = requested_release
        else:
            if debug:
                print(f"Requested release ({requested_release}) not valid, searching for valid release.")
            if search == 'latest':
                selected_release = Version(minor_releases[-1])
            elif search == 'backward':
                for minor_release in minor_releases:
                    if minor_release < requested_release:
                        selected_release = minor_release
            elif search == 'forward':
                for minor_release in minor_releases:
                    if minor_release > requested_release:
                        selected_release = minor_release
                        break
            else:
                utils.exit_msg(f"Invalid search '{search}'. Must be one of forward, backward, or latest")

    return selected_release


def select_tag(component, releases, release, image_names, tag=None, all_tags=False, debug=False):
    """
    Select the best tag based on the component, release, and/or tag.
    component: string (eg: am)
    releases: dict (generated by get_releases())
    release: Version object or alt release string
    image_names: dict (BASE_IMAGE_NAMES)

    image_names is a mapping of standard component names. The BASE_IMAGE_NAMES
    dictionary has the standard names, and it can be updated by this function
    if the selected release has defined 'component_name' in the component JSON
    file.
    """

    selected_tag = None
    modifier = 'backward'
    if isinstance(release, Version):
        if release.minor == 0 and release.micro == 0:
            modifier = 'forward'
    selected_release = get_available_release(release, releases[component], modifier, debug)
    selected_release_str = str(selected_release)
    maj_min = None
    if isinstance(selected_release, str):
        maj_min = selected_release
    else:
        maj_min = f"{selected_release.major}.{selected_release.minor}"
    if debug:
        print(f"maj_min = {maj_min}")
    if all_tags:
        selected_tag = releases[component][maj_min][selected_release_str]['tags']
    elif tag in releases[component][maj_min][selected_release_str]['tags']:
        selected_tag = tag
    else:
        selected_tag = releases[component][maj_min][selected_release_str]['tags'][-1]
    if 'component_name' in releases[component][maj_min][selected_release_str]:
        image_names[component] = releases[component][maj_min][selected_release_str]['component_name']

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
            repo = copy(BASE_REPO_DEV)

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
            repo = copy(BASE_REPO_DEV)
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
            result = re.sub("^([0-9].[0-9].[0-9]).*", r"\1", tag)
    return result

def is_valid_release(tag, debug=False):
    """
    Check if the given tag starts with an x.y.z release string.
    """

    if debug:
        print(f"is_valid_release(): tag={tag}")
    result = False
    if re.match(r'^[0-9]+.[0-9]+.[0-9]+', tag):
        result = True

    return result

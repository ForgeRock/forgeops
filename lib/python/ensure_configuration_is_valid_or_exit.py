import os
import sys
import site
from pathlib import Path
from hashlib import sha1

file_name = Path(__file__)
current_file_path = file_name.parent.resolve()
root_dir = [parent_path for parent_path in current_file_path.parents if (parent_path / 'README.md').exists()][0]
dependencies_dir = os.path.join(root_dir, 'bin', 'forgeops_scripts', 'lib', 'dependencies')
# Insert lib folders to python path
sys.path.insert(0, str(root_dir))
sys.path.insert(1, str(dependencies_dir) + site.USER_SITE.replace(site.USER_BASE, ''))
from lib.python.constants import REQUIREMENTS_FILE, FORGEOPS_SCRIPT_FILE, \
    CONFIGURED_VERSION_FILE, DEPENDENCIES_DIR
from lib.python.utils import run, warning, error
from lib.python import utils


def compute_configuration_version():
    """Create a sha1 based on the files we want to monitor the changes"""
    files_content = ""
    for file_path in [REQUIREMENTS_FILE]:
        with open(file_path) as file_stream:
            files_content += file_stream.read()
    return sha1(files_content.encode("utf-8")).hexdigest()


def in_virtualenv():
    """Checks if we are running in virtual env"""
    base_prefix_compat = getattr(sys, "base_prefix", None) or getattr(sys, "real_prefix", None) or sys.prefix
    if base_prefix_compat == sys.prefix:
        return False
    elif 'PYCHARM_HOSTED' in os.environ.keys() and os.environ['PYCHARM_HOSTED'] == '1':
        return True
    else:
        return True


def check_python_venv_lib_deps():
    """
    Compare python venv dependencies with requirements, to evaluate if they are installed.
    """

    # Load requirements file and parse into array(strip comments, newlines):
    with open(REQUIREMENTS_FILE, 'r') as req_file:
        requirements = req_file.readlines()
    tmp_req_list = []
    for req in requirements:
        if '#' not in req:
            if req.strip() != '':
                tmp_req_list.append(req.strip())
    requirements = tmp_req_list
    pip_freeze_cmd = 'pip3 freeze' if not in_virtualenv() else 'python3 -m pip freeze'
    rc, out, err = run(pip_freeze_cmd, cstdout=True, cstderr=True)
    out = out.decode("utf-8").split('\n')

    # Compare installed libs with expected.
    for req in requirements:
        if req not in out:
            warning(f'To run script through IDE, please run : pip3 install {req}')
            return False

    return True


def print_how_to_install_dependencies():
    print('You need to run "forgeops configure" command to setup your local environment.')
    sys.exit(1)


def ensure_configuration_is_valid_or_exit():
    """
    This function makes sure that configure has been run with expected version.
    """
    configured = False
    if in_virtualenv():
        # Virtualenv installs dependencies into itself rather than Forgeops lib/dependencies
        # as it ignores --user flag.
        if os.path.isfile(CONFIGURED_VERSION_FILE) and check_python_venv_lib_deps():
            configured = True
    else:
        if os.path.isfile(CONFIGURED_VERSION_FILE) and os.path.exists(DEPENDENCIES_DIR):
            configured = True

    config_cmd_to_run = f'{os.path.basename(FORGEOPS_SCRIPT_FILE)} configure'

    if not configured:
        error(f'{os.path.basename(FORGEOPS_SCRIPT_FILE)} not configured, please run {config_cmd_to_run}')
        exit(1)

    with open(CONFIGURED_VERSION_FILE, 'r') as fd:
        line = fd.readline().rstrip()
        version_configured = compute_configuration_version()
        if line != version_configured:
            error(f'{FORGEOPS_SCRIPT_FILE} configuration needs to be refreshed, please run {config_cmd_to_run}')
            exit(1)


if __name__ == '__main__':
    ensure_configuration_is_valid_or_exit()

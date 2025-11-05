#!/usr/bin/env python3
"""Upgrade a ForgeOps environment to the latest updates"""

import argparse
import site
import os
from pathlib import Path
import sys
file_name = Path(__file__)
current_file_path = file_name.parent.resolve()
root_path = [parent_path for parent_path in current_file_path.parents if (parent_path / 'README.md').exists()][0]
dependencies_dir = os.path.join(root_path, 'lib', 'dependencies')
# Insert lib folders to python path
sys.path.insert(0, str(root_path))
sys.path.insert(1, str(dependencies_dir) + site.USER_SITE.replace(site.USER_BASE, ''))

from lib.python.ensure_configuration_is_valid_or_exit import ensure_configuration_is_valid_or_exit, \
    print_how_to_install_dependencies
from lib.python.defaults import SNAPSHOT_ROLE_NAME

# First ensure configure has been executed
try:
    ensure_configuration_is_valid_or_exit()
except Exception as e:
    try:
        print(f'[error] {str(e)}')
    except Exception as exc:
        raise e from exc
    sys.exit(1)

try:
    import yaml
except:
    print_how_to_install_dependencies()
import lib.python.utils as utils


# Avoid using anchors/aliases in outputted YAML
# Notice we call this with yaml.dump, but we are still using safe_dump
# From https://ttl255.com/yaml-anchors-and-aliases-and-how-to-disable-them/
class NoAliasDumper(yaml.SafeDumper):
    """ A Dumper that doesn't use YAML aliases """
    def ignore_aliases(self, data):
        return True

def write_yaml_file(data, file):
    """Write an object to a yaml file"""
    with open(file, 'w+', encoding='utf-8') as f:
        yaml.dump(data, f, sort_keys=False, Dumper=NoAliasDumper)


def log(msg, path, verbose=True, log_file='upgrade.log', end="\n"):
    """ Log a message to the upgrade log """
    log_path = path / log_file
    if not log_path.is_file():
        msg = f"""{msg}

WARNING!! {log_path} doesn't exist, creating.
Do a `git add {log_path}` to track.
"""
    if verbose:
        print(msg, end=end)
    with open(log_path, 'a', encoding='utf-8') as log_f:
        log_f.write(f"{msg}{end}")

def setup_args():
    """ Setup the common arguments """

    common_ns = argparse.ArgumentParser(add_help=False)
    common_ns.add_argument(
        '--namespace',
        '-n',
        help='Target namespace (default: current ctx namespace)')
    common_dg = argparse.ArgumentParser(add_help=False)
    common_dg.add_argument(
        '--debug',
        '-d',
        action='store_true',
        help='Target namespace (default: current ctx namespace)')
    common_pf = argparse.ArgumentParser(add_help=False)
    common_pf.add_argument(
        '--config-profile',
        '-p',
        help='Name of config profile in docker/<component>/config-profiles')
    common_env = argparse.ArgumentParser(add_help=False)
    common_env.add_argument(
        '--env-name',
        '-e',
        help='Forgeops environment to target')
    common_env_r = argparse.ArgumentParser(add_help=False)
    common_env_r.add_argument(
        '--env-name',
        '-e',
        required=True,
        help='Forgeops environment to target')
    common_hp = argparse.ArgumentParser(add_help=False)
    common_hp.add_argument(
        '--helm-path',
        '-H',
        help='Dir to store Helm values files (absolute or relative to forgeops data dir)')
    common_kp = argparse.ArgumentParser(add_help=False)
    common_kp.add_argument(
        '--kustomize-path',
        '-k',
        help='Kustomize dir to use (absolute or relative to forgeops data dir)')
    common_src = argparse.ArgumentParser(add_help=False)
    common_src.add_argument(
        '--source',
        '-s',
        help='Name of source Kustomize overlay')

    return {
        'debug': common_dg,
        'namespace': common_ns,
        'config_profile': common_ns,
        'env_name': common_env,
        'env_name_req': common_env_r,
        'helm_path': common_hp,
        'kustomize_path': common_kp,
        'source': common_src,
    }

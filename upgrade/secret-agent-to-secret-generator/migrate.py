#!/usr/bin/env python3

import argparse
import datetime
import json
import site
import os
from pathlib import Path
import re
import shutil
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
        print(f'[error] {e.__str__()}')
    except:
        raise e
    sys.exit(1)

try:
    import yaml
    from mergedeep import merge
except:
    print_how_to_install_dependencies()
import lib.python.utils as utils


# Avoid using anchors/aliases in outputted YAML
# Notice we call this with yaml.dump, but we are still using safe_dump
# From https://ttl255.com/yaml-anchors-and-aliases-and-how-to-disable-them/
class NoAliasDumper(yaml.SafeDumper):
    def ignore_aliases(self, data):
        return True

def writeYamlFile(data, file):
    """Write an object to a yaml file"""
    with open(file, 'w+') as f:
        yaml.dump(data, f, sort_keys=False, Dumper=NoAliasDumper)


def pre_check(ns_opt):
    print('Running pre-migration checks')
    print('Checking secrets')
    problem = False
    code, out, err = utils.run('kubectl', f'get secret old-ds-env-secrets {ns_opt}', cstderr=True, cstdout=True, ignoreFail=True)
    if code:
        print('Found secret old-ds-env-secrets. Please delete.')
        print(f'kubectl delete secret old-ds-env-secrets {ns_opt}')
        problem = True
    else:
        print('Success! Did not find secret old-ds-env-secrets')
    code, out, err = utils.run('kubectl', f'get secret old-ds-passwords {ns_opt}', cstderr=True, cstdout=True, ignoreFail=True)
    if code:
        print('Found secret old-ds-passwords. Please delete.')
        print(f'kubectl delete secret old-ds-passwords {ns_opt}')
        problem = True
    else:
        print('Success! Did not find secret old-ds-passwords')
    code, out, err = utils.run('kubectl', f'get job ds-set-passwords {ns_opt}', cstderr=True, cstdout=True, ignoreFail=True)
    if code:
        print('Found job ds-set-passwords. Please delete.')
        print(f'kubectl delete job ds-set-passwords {ns_opt}')
        problem = True
    else:
        print('Success! Did not find job ds-set-passwords')
    code, out, err = utils.run('kubectl', f'get job amster {ns_opt}', cstderr=True, cstdout=True, ignoreFail=True)
    if code:
        print('Found job amster. Please delete.')
        print(f'kubectl delete job amster {ns_opt}')
        problem = True
    else:
        print('Success! Did not find job amster')

    if problem:
        print('Resolve issues listed above, and rerun the script.')
        exit(1)
    else:
        print('No issues found. Continuing.')


def delete_sac(ns_opt, dryrun=False):
    cmd_opts = f"delete sac forgerock-sac {ns_opt}"
    print("Deleting forgerock-sac")
    utils.run('kubectl', cmd_opts, dryrun=dryrun)


def edit_sac(ns_opt, dryrun=False):
    print("Removing am-env-secrets, ds-env-secrets, amster, and amster-env-secrets from forgerock-sac")
    remove = ['am-env-secrets', 'ds-env-secrets', 'amster', 'amster-env-secrets']
    code, sac_str, err = utils.run('kubectl', f"get sac forgerock-sac -o yaml {ns_opt}", cstdout=True)
    sac = yaml.safe_load(sac_str.decode('utf-8'))
    new_secrets = []
    for i in range(len(sac['spec']['secrets'])):
        if sac['spec']['secrets'][i]['name'] not in remove:
            new_secrets.append(sac['spec']['secrets'][i])
    sac['spec']['secrets'] = new_secrets
    utils.run('kubectl', f"replace {ns_opt} -f -", stdin=yaml.safe_dump(sac).encode(), dryrun=dryrun)


def run_helm_cmd(msg, values_file, chart_name, chart_version, chart_repo, namespace_opt, dryrun=False):
    print(msg)
    print("Do you want us to run this for you? (Y/N)")
    cmd = 'helm'
    repo_opt = chart_repo
    if chart_repo.startswith('http') or chart_repo.startswith('osi'):
        repo_opt = f"identity-platform --repo {chart_repo} --version {chart_version}"
    cmd_opts = f"upgrade -i {chart_name} {repo_opt} --values {values_file} {namespace_opt}"
    print(f"{cmd} {cmd_opts}")
    response = input()
    if re.search(r'^Y|y', response):
        print("Running helm")
        utils.run(cmd, cmd_opts, dryrun=dryrun)
    else:
        print("Run the above command in another terminal, then come back here to continue")


def restart_ds(namespace_opt, dryrun):
    cmd = 'kubectl'
    cmd_opts = f"rollout restart {namespace_opt} sts ds-cts ds-idrepo"
    print("Restarting DS with kubectl rollout restart")
    print("Do you want us to run this for you? (Y/N)")
    print(f"{cmd} {cmd_opts}")
    response = input()
    if re.search(r'^Y|y', response):
        print("Restarting DS")
        utils.run(cmd, cmd_opts, dryrun=dryrun)
    else:
        print("Run the above command in another terminal, then come back here to continue")
    print("Press <ENTER> to continue once DSes have all restarted and are Ready")
    response = input()


def toggle_ds_set_passwords_force(values_file, values, bool, write=True):
    bool_str = str(bool).lower()
    print(f"Setting ds_set_passwords.force to {bool_str} in {values_file}")
    if values.get('ds_set_passwords'):
        values['ds_set_passwords']['force'] = bool
    else:
        values['ds_set_passwords'] = { 'force': bool }
    if write:
        writeYamlFile(values, values_file)


def rotate_secret(secret, ns_opt, dryrun=False):
    cmd_opts = f"rotate {ns_opt} --yes {secret}"
    cmd = f"{root_path}/bin/forgeops"
    print(f"Running '{cmd} {cmd_opts}'")
    utils.run(cmd, cmd_opts, dryrun=dryrun)


def do_helm(args, settings):
    """ Do the procedure for Helm installs """

    utils.check_path(settings['helm_path'], 'Helm path', 'dir', True)
    settings['helm_path'] = settings['helm_path'] / args.env_name
    if args.debug: print(f"helm_path={config['helm_path']}")

    sg_values_file = root_path / 'charts' / 'identity-platform' / 'values-secret-generator.yaml'
    sg_values = yaml.safe_load(open(sg_values_file))
    values_file = settings['helm_path'] / 'values.yaml'
    values = {}
    if values_file.is_file():
        values = yaml.safe_load(open(values_file))
    else:
        utils.exit_msg(f"Missing values.yaml ({values_file}). Run this against an existing environment.")

    toggle_ds_set_passwords_force(values_file, values, True, write=False)

    values = merge(values, sg_values)
    values['platform']['disable_secret_agent_config'] = False

    values['platform']['secrets'].pop('keystore_create', None)
    values['platform']['secrets'].pop('ds_passwords', None)
    values['platform']['secrets'].pop('idm_env_secrets', None)

    print(f"Updating {values_file} with secret-generator settings")
    writeYamlFile(values, values_file)

    rotate_secret('ds-env-secrets', settings['namespace_opt'], dryrun=args.dryrun)
    edit_sac(settings['namespace_opt'], dryrun=args.dryrun)
    run_helm_cmd("Run helm to apply new secrets", values_file, args.chart_name, args.chart_version, args.chart_repo, settings['namespace_opt'], dryrun=args.dryrun)

    print("Once the ds-set-passwords job has finished and all pods are Ready, press <ENTER> to continue.")
    response = input()

    toggle_ds_set_passwords_force(values_file, values, False)

    print(f"Merging remaining secrets into {values_file}")
    values = merge(values, sg_values)
    writeYamlFile(values, values_file)

    rotate_secret('ds-passwords', settings['namespace_opt'], dryrun=args.dryrun)
    delete_sac(settings['namespace_opt'], args.dryrun)
    run_helm_cmd("Run helm to apply new secrets", values_file, args.chart_name, args.chart_version, args.chart_repo, settings['namespace_opt'], dryrun=args.dryrun)

    restart_ds(settings['namespace_opt'], args.dryrun)

    print("Deleting old secrets old-ds-env-secrets old-ds-passwords")
    cmd = 'kubectl'
    cmd_opts = f"delete secrets {settings['namespace_opt']} old-ds-env-secrets old-ds-passwords"
    utils.run(cmd, cmd_opts, dryrun=args.dryrun)

    toggle_ds_set_passwords_force(values_file, values, True)

    run_helm_cmd("Run helm to delete old DS secrets", values_file, args.chart_name, args.chart_version, args.chart_repo, settings['namespace_opt'], dryrun=args.dryrun)
    restart_ds(settings['namespace_opt'], args.dryrun)

    toggle_ds_set_passwords_force(values_file, values, False)


def do_kustomize(args, settings):
    """ Do the procedure for Kustomize installs """

    utils.check_path(settings['kustomize_path'], 'Kustomize path', 'dir', True)
    utils.check_path(settings['overlay_root'], 'Overlay root path', 'dir', True)
    overlay_path = settings['overlay_root'] / args.env_name
    default_path = overlay_path / 'default'
    default_secrets = default_path / 'secrets'
    secrets_path = overlay_path / 'secrets'
    sa_path = secrets_path / 'secret-agent'
    sg_path = secrets_path / 'secret-generator'
    if args.debug: print(f"overlay_path={config['overlay_path']}")

    if overlay_path.exists() and overlay_path.is_dir():
        print(f"{overlay_path} is a directory, continuing.")
    else:
        print(f"{overlay_path} is not a directory. Please specify an existing ForgeOps environment.")
        exit(1)

    sac_patch = {
        'path': 'sac-patch.yaml',
        'target': {
            'group': 'secret-agent.secrets.forgerock.io',
            'version': 'v1alpha1',
            'kind': 'SecretAgentConfiguration',
            'name': 'forgerock-sac'
        }
    }

    sg_patch = {
        'path': 'sg-patch.yaml'
    }

    # Setup patch in overlay to remove secrets
    rotate_secret('ds-env-secrets', settings['namespace_opt'], dryrun=args.dryrun)
    edit_sac(settings['namespace_opt'], dryrun=args.dryrun)

    # Modify secret overlays
    if secrets_path.is_dir():
        if sa_path.is_dir() and sg_path.is_dir():
            print("The secrets sub-overlay has been migrated, continuing.")
        else:
            print("The secrets sub-overlay has not been migrated. Migrating.")
            backup_path = overlay_path / 'secrets.bak'
            print(f"Backing up current secrets dir to {backup_path}")
            secrets_path.rename(backup_path)
            print(f"Bringing in new secrets/ from {default_secrets}")
            shutil.copytree(default_secrets, secrets_path)
    else:
        print(f"{secrets_path} doesn't exist, copying from {default_secrets}")
        shutil.copytree(default_secrets, secrets_path)

    print(f"Configuring overlay ({args.env_name}) for both secret-agent and secret-generator")
    sec_kust_file = secrets_path / 'kustomization.yaml'
    sa_kust_file = secrets_path / 'secret-agent' / 'kustomization.yaml'
    sg_kust_file = secrets_path / 'secret-generator' / 'kustomization.yaml'
    sec_kust = {}
    sa_kust = {}
    sg_kust = {}
#    if sec_kust_file.is_file():
#        sec_kust = yaml.safe_load(open(sec_kust_file)
#    if sa_kust_file.is_file():
#        sa_kust = yaml.safe_load(open(sa_kust_file)
#    if sg_kust_file.is_file():
#        sg_kust = yaml.safe_load(open(sg_kust_file)

    print("Setting up secret-agent patch")

    # Run kubectl apply -k on ds-set-passwords
    # Restart AM


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Migrate secrets from secret-agent to secret-generator",
                                     prog="migrate",
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('--debug', '-d', action='store_true', help='Turn on debugging')
    parser.add_argument('--dryrun', '-r', action='store_true', help='Do a dry run')
    parser.add_argument('--chart-name', '-c', default="identity-platform", help='Name of Helm chart as installed')
    parser.add_argument('--chart-version', '-v', default="2025.2.0", help='Version of Helm chart to apply')
    parser.add_argument('--chart-repo', '-o', default="https://ForgeRock.github.io/forgeops", help='Helm repository to use')
    parser.add_argument('--env-name', '-e', required=True, help='Name of environment to manage')
    parser.add_argument('--namespace', '-n', help='Namespace to set in the overlay')
    parser.add_argument('--helm-path', '-H', help='Dir to store Helm values files (absolute or relative to forgeops root)')
    parser.add_argument('--kustomize-path', '-k', help='Kustomize dir to use (absolute or relative to forgeops root)')

    env_type = parser.add_mutually_exclusive_group()
    env_type.add_argument('--helm', '-m', action='store_true', help='Environment is deployed with Helm')
    env_type.add_argument('--kustomize', '-K', action='store_true', help='Environment is deployed with Kustomize')

    args = parser.parse_args()

    # Setup defaults for values that can be set in forgeops.conf
    overrides = utils.process_overrides(root_path,
                                        getattr(args, 'helm_path', None),
                                        getattr(args, 'kustomize_path', None),
                                        getattr(args, 'build_path', None),
                                        getattr(args, 'no_helm', False),
                                        getattr(args, 'no_kustomize', False),
                                        getattr(args, 'releases_src', None),
                                        getattr(args, 'pull_policy', None),
                                        getattr(args, 'source', None),
                                        getattr(args, 'ssl_secretname', None),
                                        args.debug)

    config = {}
    config['script_path'] = Path(__file__).parent
    if args.debug: print(f"script_path = {config['script_path']}")
    config['root_path'] = config['script_path'].parent.parent
    if args.debug: print(f"root_path = {config['root_path']}")

    config = merge(config, overrides)

    if getattr(args, 'namespace', None):
        config['namespace_opt'] = f'-n {args.namespace}'
    else:
        ns = utils.get_namespace()
        config['namespace_opt'] = f'-n {ns}'

    msg = """
This script will help you migrate your secrets from secret-agent to
secret-generator. Before continuting, make sure that your DS images have been
built with the ForgeOps 2025.2.0 release. This release includes a configuration
setting that allows for multiple password values in DS so it's possible to do
no downtime password rotations.

WARNING! This script will make changes in your Kubernetes context. Make sure
you are pointed at the correct context before continuing.

"""

    print(msg)

    pre_check(config['namespace_opt'])

    if args.helm:
        do_helm(args, config)

    if args.kustomize:
        #do_kustomize(args, config)
        print("Doing Kustomzie steps")

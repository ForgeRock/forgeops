#!/usr/bin/env python3

import argparse
import datetime
import site
import os
from pathlib import Path
import shutil
import sys
import tempfile
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
    """ Setup SafeDumper to ignore Yaml aliasing """
    def ignore_aliases(self, data):
        return True

def write_yaml_file(data, file):
    """Write an object to a yaml file"""
    with open(file, 'w+', encoding='utf-8') as f:
        yaml.dump(data, f, sort_keys=False, Dumper=NoAliasDumper)


def check_job(job, ns_opt, dryrun=False):
    """ Check to see if a job exists. If it does, then offer to delete it.
        Return True if it does, otherwise return False """
    is_pass, _, _ = utils.run('kubectl', f"get job {job} {ns_opt}", cstderr=True,
                           cstdout=True, ignoreFail=True)
    if is_pass:
        cmd = 'kubectl'
        cmd_opts = f"delete job {job} {ns_opt}"
        print(f"Found job {job}. Please delete.")
        print(f"{cmd} {cmd_opts}")
        print('Would you like us to run this for you? (Y/N)')
        response = input()
        if response.lower().startswith('y'):
            utils.run(cmd, cmd_opts, dryrun=dryrun)
            return False
        return True
    return False


def check_secret(secret, ns_opt, settings):
    """ Check to see if a secret exists. If it does, then offer to delete it.
        Return True if it does, otherwise return False """
    is_pass, _, _ = utils.run('kubectl', f'get secret {secret} {ns_opt}', cstderr=True,
                           cstdout=True, ignoreFail=True)
    key_str = secret.replace('-', '_')
    if is_pass:
        print('Found secret {secret} Skipping rotation.')
        settings['skip'][key_str] = True
    else:
        print('Success! Did not find secret old-ds-passwords')
        settings['skip'][key_str] = False


def pre_check(params, settings):
    """ Check to make sure we are ready to go """
    ns_opt = settings['namespace_opt']
    print('Running pre-migration checks')
    print('Checking secrets')
    is_problem = False
    settings['skip'] = {}
    if params.kustomize:
        print('Checking to see if the kustomize command is installed')
        if shutil.which('kustomize') is None:
            err_msg = """
Failure! The kustomize command is not installed or in the path. Please install kustomize into your path.
"""
            print(err_msg)
            is_problem = True
        else:
            print('Success! The kustomize command exists and is in the path.')
    check_secret('old-ds-env-secrets', ns_opt, settings)
    check_secret('old-ds-passwords', ns_opt, settings)
    is_problem = check_job('ds-set-passwords', ns_opt, dryrun=params.dryrun) or is_problem
    is_problem = check_job('amster', ns_opt, dryrun=params.dryrun) or is_problem

    if is_problem:
        utils.exit_msg('Resolve issues listed above, and rerun the script.')
    else:
        print('No issues found. Continuing.')


def upgrade_env(params, settings):
    """ Run `forgeops upgrade` on the given env """
    cmd = f"{root_path}/bin/forgeops"
    cmd_opts = f"upgrade -e {params.env_name} -k {settings['kustomize_path']} -h {settings['helm_path']}"
    print(f"You need to upgrade your env ({params.env_name})")
    print("Press <ENTER> to proceed.")
    input()
    utils.run(cmd, cmd_opts, dryrun=params.dryrun)


def switch_env(params, settings):
    """ Switch env over to secret-generator """
    k_path = settings['kustomize_path']
    h_path = settings['helm_path']
    env_name = params.env_name
    cmd = f"{root_path}/bin/forgeops"
    cmd_opts = f"env -e {env_name} -k {k_path} -H {h_path} {settings['namespace_opt']} --secret-generator"
    print(f"Switching {params.env_name} env to secret-generator")
    print(f"{cmd} {cmd_opts}")
    print("Press <ENTER> to proceed.")
    input()
    utils.run(cmd, cmd_opts, dryrun=params.dryrun)


def is_k8s_resource(res_type, res, ns_opt):
    """ Check to see if a Kubernetes resource exists """
    is_pass, _, _ = utils.run('kubectl', f"get {res_type} {res} -o yaml {ns_opt}",
                                   cstdout=True, cstderr=True, ignoreFail=True)
    if not is_pass:
        print(f"Can't find {res_type} {res}. Skipping.")
    return is_pass


def delete_sac(ns_opt, dryrun=False):
    """ Delete the SecretAgentConfiguration """
    if not is_k8s_resource('sac', 'forgerock-sac', ns_opt):
        return
    cmd = 'kubectl'
    cmd_opts = f"delete sac forgerock-sac {ns_opt}"
    print("Now we need to delete the old forgerock-sac.")
    print(f"{cmd} {cmd_opts}")
    print("Would you like us to run this for you? (Y/N)")
    response = input()
    if response.lower().startswith('y'):
        utils.run('kubectl', cmd_opts, dryrun=dryrun)
    else:
        print("Run the above command in another terminal, then press <ENTER> to continue")
        input()


def edit_sac(ns_opt, dryrun=False):
    """ Edit SecretAgentConfiguration to remove secrets """
    if not is_k8s_resource('sac', 'forgerock-sac', ns_opt):
        return
    remove = ['am-env-secrets', 'ds-env-secrets', 'amster', 'amster-env-secrets']
    print(f"Removing {', '.join(remove)} from forgerock-sac")
    _, sac_str, _ = utils.run('kubectl', f"get sac forgerock-sac -o yaml {ns_opt}",
                                   cstdout=True, ignoreFail=True)
    sac = yaml.safe_load(sac_str.decode('utf-8'))
    new_secrets = []
    for i in range(len(sac['spec']['secrets'])):
        if sac['spec']['secrets'][i]['name'] not in remove:
            new_secrets.append(sac['spec']['secrets'][i])
    sac['spec']['secrets'] = new_secrets
    cmd = 'kubectl'
    cmd_opts = f"replace {ns_opt} -f -"
    print("Replacing forgerock-sac to remove migrated secrets.")
    print(f"{cmd} {cmd_opts}")
    print("Press <ENTER> to proceed.")
    input()
    utils.run(cmd, cmd_opts, stdin=yaml.safe_dump(sac).encode(),
              dryrun=dryrun)


def run_helm_cmd(msg, values_file, chart_name, chart_version, chart_repo, namespace_opt, dryrun=False):
    """ Run Helm command """
    print(msg)
    print("Do you want us to run this for you? (Y/N)")
    cmd = 'helm'
    repo_opt = chart_repo
    if chart_repo.startswith('http') or chart_repo.startswith('osi'):
        repo_opt = f"identity-platform --repo {chart_repo} --version {chart_version}"
    cmd_opts = f"upgrade -i {chart_name} {repo_opt} --values {values_file} {namespace_opt}"
    print(f"{cmd} {cmd_opts}")
    response = input()
    if response.lower().startswith('y'):
        print("Running helm")
        utils.run(cmd, cmd_opts, dryrun=dryrun)
    else:
        print("Run the above command in another terminal, then press <ENTER> to continue")
        input()


def apply_overlay(overlay_path, ns_opt, params):
    """ Apply Kustomize overlay """
    kust_cmd = 'kustomize'
    kust_cmd_opts = f"build {overlay_path}"
    k_cmd = 'kubectl'
    k_cmd_opts = f"apply {ns_opt} -f -"
    print(f"Apply the {params.env_name} overlay:")
    print(f"{kust_cmd} {kust_cmd_opts} | {k_cmd} {k_cmd_opts}")
    print('Do you want us to run this for you? (Y/N)')
    response = input()
    if response.lower().startswith('y'):
        _, contents, _ = utils.run(kust_cmd, kust_cmd_opts, cstdout=True)
        contents = contents.decode('ascii')
        utils.run(k_cmd, k_cmd_opts, stdin=bytes(contents, 'ascii'), dryrun=params.dryrun)
        if params.dryrun:
            with tempfile.TemporaryDirectory(prefix='sa2sg') as tmp_dir:
                tmp_file = f"{tmp_dir}/kustomize.out"
                with open(tmp_file, 'w', encoding='utf-8') as f:
                    f.write(contents)
                print(f"Generated manifest in {tmp_file}")
    else:
        print("Run the command in another terminal, and wait until the ds-set-passwords job has completed.")
        print("Press <ENTER> to continue.")
        input()


def restart_ds(namespace_opt, dryrun):
    """ Restart the DS StatefulSets """
    cmd = 'kubectl'
    cmd_opts = f"rollout restart {namespace_opt} sts ds-cts ds-idrepo"
    print("Restarting DS with kubectl rollout restart")
    print("Do you want us to run this for you? (Y/N)")
    print(f"{cmd} {cmd_opts}")
    response = input()
    if response.lower().startswith('y'):
        print("Restarting DS")
        utils.run(cmd, cmd_opts, dryrun=dryrun)
    else:
        print("Run the above command in another terminal, then come back here to continue")
    print("Press <ENTER> to continue once DSes have all restarted and are Ready")
    response = input()


def toggle_ds_set_passwords_force(values_file, values, value, write=True):
    """ Toggle ds_set_passwords.force in values.yaml """
    bool_str = str(value).lower()
    print(f"Setting ds_set_passwords.force to {bool_str} in {values_file}.")
    print("Press <ENTER> to continue")
    input()
    if values.get('ds_set_passwords'):
        values['ds_set_passwords']['force'] = value
    else:
        values['ds_set_passwords'] = { 'force': value }
    if write:
        write_yaml_file(values, values_file)


def rotate_secret(secret, ns_opt, settings, dryrun=False):
    """ Rotate a secret using `forgeops rotate` """
    if settings['skip'][f"old_{secret.replace('-', '_')}"]:
        print(f"Skipping rotation of {secret}.")
    else:
        cmd = f"{root_path}/bin/forgeops"
        cmd_opts = f"rotate {ns_opt} --yes --quiet {secret}"
        print(f"Rotating {secret} for no downtime password change.")
        print(f"{cmd} {cmd_opts}")
        print("Press <ENTER> when ready to proceed.")
        input()
        utils.run(cmd, cmd_opts, dryrun=dryrun)


def configure_patch(patch_list, search_key, search_value, data, debug=False):
    """ Search for path key in list of dictionaries. If not found, then append the data. """
    patch_found = False
    for p in patch_list:
        if isinstance(p, dict):
            if search_key in p.keys():
                if p[search_key] == search_value:
                    patch_found = True
                    break

    if not patch_found:
        patch_list.append(data)


def delete_patch(res, search_key, search_value):
    """ Search for path key in list of dictionaries. If found, then remove the data. """
    for p in res['patches']:
        if isinstance(p, dict):
            if search_key in p.keys():
                if p[search_key] == search_value:
                    continue
                res['patches'].append(p)
    if len(res['patches']) == 0:
        res.remove('patches')


def delete_old_secrets(ns_opt, dryrun=False):
    """ Delete old-ds-* secrets """
    print("Deleting old secrets old-ds-env-secrets old-ds-passwords")
    cmd = 'kubectl'
    cmd_opts = f"delete secrets {ns_opt} old-ds-env-secrets old-ds-passwords"
    print("Would you like us to run this for you? (Y/N)")
    print(f"{cmd} {cmd_opts}")
    response = input()
    if response.lower().startswith('y'):
        utils.run(cmd, cmd_opts, dryrun=dryrun)
    else:
        print("Please run the above command, then come back and press <ENTER>.")
        input()


def do_helm(params, settings):
    """ Do the procedure for Helm installs """

    utils.check_path(settings['helm_path'], 'Helm path', 'dir', True)
    settings['helm_path'] = settings['helm_path'] / params.env_name
    if params.debug:
        print(f"helm_path={settings['helm_path']}")

    switch_env(params, settings)
    values_file = settings['helm_path'] / 'values.yaml'
    values = {}
    if values_file.is_file():
        with open(values_file, 'r', encoding='utf-8') as f:
            values = yaml.safe_load(f)
    else:
        err_msg = f"Missing values.yaml ({values_file}). Run this against an existing environment."
        utils.exit_msg(err_msg)

    toggle_ds_set_passwords_force(values_file, values, True, write=False)
    values['platform']['disable_secret_agent_config'] = False
    values['platform']['secrets'].pop('keystore_create', None)
    values['platform']['secrets'].pop('ds_passwords', None)
    values['platform']['secrets'].pop('idm_env_secrets', None)

    print(f"Updating {values_file} with secret-generator settings")
    print("Press <ENTER> to continue when ready.")
    input()
    write_yaml_file(values, values_file)

    rotate_secret('ds-env-secrets', settings['namespace_opt'], settings, dryrun=params.dryrun)
    edit_sac(settings['namespace_opt'], dryrun=params.dryrun)
    run_helm_cmd("Run helm to apply new secrets",
                 values_file, params.chart_name, params.chart_version,
                 params.chart_repo, settings['namespace_opt'], dryrun=params.dryrun)

    print("Once the ds-set-passwords job has finished and all pods are Ready, press <ENTER> to continue.")
    input()

    toggle_ds_set_passwords_force(values_file, values, False)

    print(f"Merging remaining secrets into {values_file}. Press <ENTER> to proceed.")
    input()
    sg_values_file = root_path / 'charts' / 'identity-platform' / 'values-secret-generator.yaml'
    sg_values = {}
    with open(sg_values_file, 'r', encoding='utf-8') as f:
        sg_values = yaml.safe_load(f)
    values = merge(values, sg_values)
    write_yaml_file(values, values_file)

    rotate_secret('ds-passwords', settings['namespace_opt'], settings, dryrun=params.dryrun)
    delete_sac(settings['namespace_opt'], params.dryrun)
    run_helm_cmd("Run helm to apply new secrets",
                 values_file, params.chart_name, params.chart_version,
                 params.chart_repo, settings['namespace_opt'], dryrun=params.dryrun)

    restart_ds(settings['namespace_opt'], params.dryrun)

    delete_old_secrets(settings['namespace_opt'], params['debug'])

    toggle_ds_set_passwords_force(values_file, values, True)

    run_helm_cmd("Run helm to delete old DS secrets",
                 values_file, params.chart_name, params.chart_version,
                 params.chart_repo, settings['namespace_opt'], dryrun=params.dryrun)
    restart_ds(settings['namespace_opt'], params.dryrun)

    toggle_ds_set_passwords_force(values_file, values, False)


def do_kustomize(params, settings):
    """ Do the procedure for Kustomize installs """

    utils.check_path(settings['kustomize_path'], 'Kustomize path', 'dir', True)
    utils.check_path(settings['overlay_root'], 'Overlay root path', 'dir', True)
    overlay_path = settings['overlay_root'] / params.env_name
    default_path = overlay_path / 'default'
    default_secrets = default_path / 'secrets'
    secrets_path = overlay_path / 'secrets'
    sa_path = secrets_path / 'secret-agent'
    sg_path = secrets_path / 'secret-generator'
    if params.debug:
        print(f"overlay_path={overlay_path}")

    if overlay_path.exists() and overlay_path.is_dir():
        print(f"{overlay_path} is a directory, continuing.")
    else:
        err_msg = f"{overlay_path} is not a directory. Please specify an existing ForgeOps environment."
        utils.exit_msg(err_msg)

    # Modify secret overlays
    if secrets_path.is_dir():
        if sa_path.is_dir() and sg_path.is_dir():
            print("The secrets sub-overlay has been migrated, continuing.")
        else:
            print("The secrets sub-overlay has not been upgraded. Upgrading.")
            upgrade_env(params, settings)
    else:
        print(f"{secrets_path} doesn't exist, copying from {default_secrets}")
        shutil.copytree(default_secrets, secrets_path)

    switch_env(params, settings)
    sg_kust_file = secrets_path / 'secret-generator' / 'kustomization.yaml'
    sg_kust = {}
    if sg_kust_file.is_file():
        with open(sg_kust_file, 'r', encoding='utf-8') as f:
            sg_kust = yaml.safe_load(f)
    else:
        utils.exit_msg(f"Can't find {sg_kust_file}. Check your {params.env_name} environment. Exiting.")

    print("Setting up secret-generator patch. Press <ENTER> to continue.")
    input()
    sg_patch_fn = 'sg-patch.yaml'
    sg_patch = {
        'path': sg_patch_fn
    }
    if 'patches' not in sg_kust.keys():
        sg_kust['patches'] = []
    configure_patch(sg_kust['patches'], 'path', sg_patch_fn, sg_patch, params.debug)
    shutil.copy(f"{current_file_path}/{sg_patch_fn}", f"{secrets_path}/secret-generator")
    # Write files
    write_yaml_file(sg_kust, sg_kust_file)

    rotate_secret('ds-env-secrets', settings['namespace_opt'], settings, dryrun=params.dryrun)
    edit_sac(settings['namespace_opt'], dryrun=params.dryrun)

    # Apply the secrets and ds-set-passwords child overlays
    print('Next we need to apply the secrets and ds-env-secrets child overlays.')
    apply_overlay(f"{overlay_path}/secrets", settings['namespace_opt'], params)
    apply_overlay(f"{overlay_path}/ds-set-passwords", settings['namespace_opt'], params)

#    cmd = ['kubectl', f"{settings['namespace_opt']} rollout restart deployment am"]
#    print('AM must be restarted to pick up new secrets.')
#    print(f"{' '.join(cmd)}")
#    print('Do you want us to restart AM for you? (Y/N)')
#    response = input()
#    if response.lower().startswith('y'):
#        utils.run(cmd[0], cmd[1], dryrun=params.dryrun)
#    else:
#        print("Run the command in another terminal, and wait until ds-set-passwords is complete.")
#        print("Press <ENTER> to continue.")
#        input()

    rotate_secret('ds-passwords', settings['namespace_opt'], settings, dryrun=params.dryrun)
    delete_sac(settings['namespace_opt'], params.dryrun)

    # Delete patches and patch files
    print("Deleting temporary patches. Press <ENTER> to continue.")
    input()
    delete_patch(sg_kust, 'path', sg_patch_fn)
    if len(sg_kust['patches']) == 0:
        sg_kust.remove('patches')
    # Write files
    write_yaml_file(sg_kust, sg_kust_file)
    # Apply the overlay
    apply_overlay(overlay_path, settings['namespace_opt'], params)
    # Restart DS
    restart_ds(settings['namespace_opt'], params.dryrun)
    delete_old_secrets(settings['namespace_opt'], params.debug)

    apply_overlay(f"{overlay_path}/ds-set-passwords", settings['namespace_opt'], params)
    restart_ds(settings['namespace_opt'], params.dryrun)


class MigrateFormatter(argparse.ArgumentDefaultsHelpFormatter, argparse.RawDescriptionHelpFormatter):
    pass


if __name__ == '__main__':
    PROG = 'migrate.py'
    DESC = "Migrate secrets from secret-agent to secret-generator"
    EPILOG = f"""
  Requirements:
    * Must have kustomize command installed and in your path

  Examples:
    Migrate a Helm deployment:
    ./{PROG} -e ENV_NAME -m

    Migrate a Kustomize deployment:
    ./{PROG} -e ENV_NAME -K

"""
    parser = argparse.ArgumentParser(description=DESC,
                                     prog=PROG,
                                     epilog=EPILOG,
                                     formatter_class=MigrateFormatter)
    parser.add_argument('--debug', '-d', action='store_true', help='Turn on debugging')
    parser.add_argument('--dryrun', '-r', action='store_true', help='Do a dry run')
    parser.add_argument('--chart-name', '-c', default="identity-platform",
                        help='Name of Helm chart as installed')
    parser.add_argument('--chart-version', '-v', default="2025.2.0",
                        help='Version of Helm chart to apply')
    parser.add_argument('--chart-repo', '-o', default="https://ForgeRock.github.io/forgeops",
                        help='Helm repository to use')
    parser.add_argument('--env-name', '-e', required=True, help='Name of environment to manage')
    parser.add_argument('--namespace', '-n', help='Namespace to set in the overlay')
    parser.add_argument('--helm-path', '-H',
                        help='Dir to store Helm values files (abs or rel to forgeops_data)')
    parser.add_argument('--kustomize-path', '-k',
                        help='Kustomize dir to use (abs or rel to forgeops_data)')

    env_type = parser.add_mutually_exclusive_group()
    env_type.add_argument('--helm', '-m', action='store_true',
                          help='Environment is deployed with Helm')
    env_type.add_argument('--kustomize', '-K', action='store_true',
                          help='Environment is deployed with Kustomize')

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
    if args.debug:
        print(f"script_path = {config['script_path']}")
    config['root_path'] = config['script_path'].parent.parent
    if args.debug:
        print(f"root_path = {config['root_path']}")

    config = merge(config, overrides)

    if getattr(args, 'namespace', None):
        config['namespace_opt'] = f'-n {args.namespace}'
    else:
        ns = utils.get_namespace()
        print(f"No namespace given, getting it from your context. ns = {ns}")
        config['namespace_opt'] = f'-n {ns}'

    MSG = """
This script will help you migrate your secrets from secret-agent to
secret-generator. Before continuing, make sure that your DS images have been
built with the ForgeOps 2025.2.0 release. This release includes a configuration
setting that allows for multiple password values in DS so it's possible to do
no downtime password rotations.

WARNING! This script will make changes in your Kubernetes context. Make sure
you are pointed at the correct context before continuing.

Before continuing make sure you have done the following:
    * Backup your secrets
        * am-env-secrets
        * am-keystore
        * am-passwords
        * amster
        * amster-env-secrets
        * ds-env-secrets
        * ds-passwords
        * idm-env-secrets
        * idm
    * Upgrade to ForgeOps 2025.2.0
    * Deploy DS image with no downtime password rotation capability
        * Not required, but useful
        * Can use `forgeops build` in 2025.2.0 to build a new image
        * Must deploy the image after building

Would you like to continue? (Y/N)

"""

    print(MSG)
    response = input()
    if response.lower().startswith('y'):
        print("Proceeding with migration.")
    else:
        print("Ok we will exit. Come back when you are ready.")
        sys.exit(0)

    pre_check(args, config)

    if args.helm:
        do_helm(args, config)

    if args.kustomize:
        do_kustomize(args, config)

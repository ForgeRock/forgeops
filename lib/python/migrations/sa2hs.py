#!/usr/bin/env python3
""" Migrate from secret-agent to helm-secrets """

import argparse
import sys
import yaml
from mergedeep import merge
import lib.python.utils as utils
from lib.python.common import write_yaml_file


def check_secret(secret, ns_opt, settings):
    """ Check to see if a secret exists. If it does, then offer to delete it.
        Return True if it does, otherwise return False """
    is_pass, _, _ = utils.run('kubectl', f'get secret {secret} {ns_opt}', cstderr=True,
                           cstdout=True, ignoreFail=True)
    key_str = secret.replace('-', '_')
    if is_pass:
        print(f"Found secret {secret} Skipping rotation.")
        settings['skip'][key_str] = True
    else:
        print(f"Success! Did not find secret {secret}")
        settings['skip'][key_str] = False


def pre_check(params, settings):
    """ Check to make sure we are ready to go """
    ns_opt = settings['namespace_opt']
    print('Running pre-migration checks')
    print('Checking secrets')
    is_problem = False
    settings['skip'] = {}
    settings['helm_env_path'] = settings['helm_path'] / params.env_name
    if params.debug:
        print(f"helm_env_path={settings['helm_env_path']}")
    helm_env_path = settings['helm_env_path']
    if utils.check_path(helm_env_path, 'Helm path', 'dir', True):
        print(f'Success! {helm_env_path} is a dir')
    else:
        print(f'{helm_env_path} is not a dir. Check --env-name and try again.')
        is_problem = True
    check_secret('old-ds-env-secrets', ns_opt, settings)
    check_secret('old-ds-passwords', ns_opt, settings)

    if is_problem:
        utils.exit_msg('Resolve issues listed above, and rerun the script.')
    else:
        print('No issues found. Continuing.')


def upgrade_env(params, settings):
    """ Run `forgeops upgrade` on the given env """
    cmd = f"{settings['root_path']}/bin/forgeops"
    cmd_opts = f"env --upgrade -e {params.env_name} -k {settings['kustomize_path']} -H {settings['helm_path']}"
    print(f"You need to upgrade your env ({params.env_name})")
    print("Press <ENTER> to proceed.")
    input()
    utils.run(cmd, cmd_opts, dryrun=params.dryrun, debug=params.debug)


def switch_env(params, settings):
    """ Switch env over to helm-secrets """
    env_name = params.env_name
    cmd = f"{settings['root_path']}/bin/forgeops"
    cmd_opts = f"env -e {env_name} -H {settings['helm_path']} {settings['namespace_opt']} --helm-secrets"
    print(f"Switching {params.env_name} env to helm-secrets")
    print(f"{cmd} {cmd_opts}")
    print("Press <ENTER> to proceed.")
    input()
    utils.run(cmd, cmd_opts, dryrun=params.dryrun, debug=params.debug)


def is_k8s_resource(res_type, res, ns_opt):
    """ Check to see if a Kubernetes resource exists """
    is_pass, _, _ = utils.run('kubectl', f"get {res_type} {res} -o yaml {ns_opt}",
                                   cstdout=True, cstderr=True, ignoreFail=True)
    if not is_pass:
        print(f"Can't find {res_type} {res}. Skipping.")
    return is_pass


def delete_sac(ns_opt, params):
    """ Delete the SecretAgentConfiguration """
    if not is_k8s_resource('sac', 'forgerock-sac', ns_opt):
        return
    cmd = 'kubectl'
    cmd_opts = f"delete sac forgerock-sac {ns_opt}"
    print("Now we need to delete the old forgerock-sac with the following command.")
    print(f"\n{cmd} {cmd_opts}")
    print("Would you like us to run this for you? (Y/N)")
    response = input()
    if response.lower().startswith('y'):
        utils.run('kubectl', cmd_opts, dryrun=params.dryrun, debug=params.debug)
    else:
        print("Run the above command in another terminal, then press <ENTER> to continue")
        input()


def edit_sac(ns_opt, params):
    """ Edit SecretAgentConfiguration to remove secrets """
    if not is_k8s_resource('sac', 'forgerock-sac', ns_opt):
        return
    remove = ['am-env-secrets', 'ds-env-secrets', 'amster', 'amster-env-secrets']
    print(f"Removing {', '.join(remove)} from forgerock-sac")
    _, sac_str, _ = utils.run('kubectl', f"get sac forgerock-sac -o yaml {ns_opt}",
                                   cstdout=True, ignoreFail=True)
    if sac_str:
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
                  dryrun=params.dryrun, debug=params.debug)


def run_helm_cmd(msg, values_file, chart_name, chart_version, chart_repo,
                 namespace_opt, params, force_ds_passwords=False):
    """ Run Helm command """
    print(msg)
    cmd = 'helm'
    repo_opt = chart_repo
    if chart_repo.startswith('http'):
        repo_opt = f"identity-platform --repo {chart_repo} --version {chart_version}"
    cmd_opts = f"upgrade -i {chart_name} {repo_opt} --values {values_file} {namespace_opt}"
    if force_ds_passwords:
        cmd_opts = f"{cmd_opts} --set ds_set_passwords.force=true"
    print(f"\n{cmd} {cmd_opts}")
    print("Do you want us to run this for you? (Y/N)")
    response = input()
    if response.lower().startswith('y'):
        print("Running helm")
        utils.run(cmd, cmd_opts, dryrun=params.dryrun, debug=params.debug)
    else:
        print("Run the above command in another terminal, then press <ENTER> to continue")
        input()


def restart_ds(namespace_opt, params, skip_input=False):
    """ Restart the DS StatefulSets """
    cmd = 'kubectl'
    cmd_opts = f"rollout restart {namespace_opt} sts ds-cts ds-idrepo"
    print("Restarting DS with kubectl rollout restart")
    print(f"\n{cmd} {cmd_opts}")
    print("Do you want us to run this for you? (Y/N)")
    response = input()
    if response.lower().startswith('y'):
        print("Restarting DS")
        utils.run(cmd, cmd_opts, dryrun=params.dryrun, debug=params.debug)
    else:
        print("Run the above command in another terminal, then come back here to continue")
    if not skip_input:
        print("Press <ENTER> to continue once DSes have all restarted and are Ready")
        response = input()


def rotate_secret(secret, ns_opt, settings, params):
    """ Rotate a secret using `forgeops rotate` """
    if settings['skip'][f"old_{secret.replace('-', '_')}"]:
        print(f"Skipping rotation of {secret}.")
    else:
        cmd = f"{settings['root_path']}/bin/forgeops"
        cmd_opts = f"rotate {ns_opt} --yes --quiet {secret}"
        print(f"Rotating {secret} for no downtime password change.")
        print(f"{cmd} {cmd_opts}")
        print("Press <ENTER> when ready to proceed.")
        input()
        utils.run(cmd, cmd_opts, dryrun=params.dryrun, debug=params.debug)


def delete_old_secrets(ns_opt, params):
    """ Delete old-ds-* secrets """
    print("Deleting old secrets old-ds-env-secrets old-ds-passwords")
    cmd = 'kubectl'
    cmd_opts = f"delete secrets {ns_opt} old-ds-env-secrets old-ds-passwords"
    print(f"\n{cmd} {cmd_opts}")
    print("Would you like us to run this for you? (Y/N)")
    response = input()
    if response.lower().startswith('y'):
        utils.run(cmd, cmd_opts, dryrun=params.dryrun, debug=params.debug, ignoreFail=True)
    else:
        print("Please run the above command, then come back and press <ENTER>.")
        input()


def do_helm(params, settings):
    """ Do the procedure for Helm installs """
    if not getattr(params, 'no_kustomize', None):
        overlay_path = settings['overlay_root'] / params.env_name
        print(f"Running upgrade on {params.env_name} to keep things consistent.", overlay_path)
        upgrade_env(params, settings)

    switch_env(params, settings)
    values_file = settings['helm_env_path'] / 'values.yaml'
    values = {}
    if values_file.is_file():
        with open(values_file, 'r', encoding='utf-8') as f:
            values = yaml.safe_load(f)
    else:
        err_msg = f"Missing values.yaml ({values_file}). Run this against an existing environment."
        utils.exit_msg(err_msg)

    if params.dryrun:
        print("DRYRUN: Setup for first set of secrets")
    else:
        values['platform']['disable_secret_agent_config'] = False
        values['platform']['secrets'].pop('keystore_create', None)
        values['platform']['secrets'].pop('ds_passwords', None)
        values['platform']['secrets'].pop('idm_env_secrets', None)

    print(f"Updating {values_file} with helm-secrets settings")
    print("Press <ENTER> to continue when ready.")
    input()
    write_yaml_file(values, values_file, dryrun=params.dryrun)

    rotate_secret('ds-env-secrets', settings['namespace_opt'], settings, params)
    edit_sac(settings['namespace_opt'], params)
    run_helm_cmd("Run helm to apply new secrets",
                 values_file, params.chart_name, params.chart_version,
                 params.chart_repo, settings['namespace_opt'], params, force_ds_passwords=True)

    print("Once the ds-set-passwords job has finished and all pods are Ready, press <ENTER> to continue.")
    input()

    print(f"Merging remaining secrets into {values_file}. Press <ENTER> to proceed.")
    input()
    hs_values_file = settings['root_path'] / 'charts' / 'identity-platform' / 'values-helm-generate-secrets.yaml'
    hs_values = {}
    with open(hs_values_file, 'r', encoding='utf-8') as f:
        hs_values = yaml.safe_load(f)
    values = merge(values, hs_values)
    write_yaml_file(values, values_file, dryrun=params.dryrun)

    rotate_secret('ds-passwords', settings['namespace_opt'], settings, params)
    delete_sac(settings['namespace_opt'], params)
    run_helm_cmd("Run helm to apply new secrets",
                 values_file, params.chart_name, params.chart_version,
                 params.chart_repo, settings['namespace_opt'], params)

    restart_ds(settings['namespace_opt'], params)

    delete_old_secrets(settings['namespace_opt'], params)

    run_helm_cmd("Run helm to delete old DS secrets",
                 values_file, params.chart_name, params.chart_version,
                 params.chart_repo, settings['namespace_opt'], params, force_ds_passwords=True)
    restart_ds(settings['namespace_opt'], params, skip_input=True)
    print("Once all DSes are all up, the migration is complete.")
    print("If you are unable to get to the login screen, clear your browser data.")


class MigrateFormatter(argparse.ArgumentDefaultsHelpFormatter, argparse.RawDescriptionHelpFormatter):
    pass


def setup_args(subparsers, common_args):
    """ Setup arguments for forgeops migrate sa2hs """

    prog = 'forgeops migrate sa2hs'
    desc = "Migrate secrets from secret-agent to Helm generated secrets"
    epilog = f"""

  Examples:
    Migrate a Helm deployment:
    ./{prog} -e ENV_NAME

"""
    parser = subparsers.add_parser('sa2hs',
                                   help=desc,
                                   prog=prog,
                                   epilog=epilog,
                                   parents=[common_args['debug'],
                                            common_args['dryrun'],
                                            common_args['env_name_req'],
                                            common_args['helm_path'],
                                            common_args['kustomize_path'],
                                            common_args['namespace'],
                                            common_args['no_kustomize']],
                                   formatter_class=MigrateFormatter)
    parser.add_argument('--chart-name', '-c', default="identity-platform",
                        help='Name of Helm chart as installed')
    parser.add_argument('--chart-version', '-v', default="2026.3.0",
                        help='Version of Helm chart to apply')
    parser.add_argument('--chart-repo', '-o', default="https://ForgeRock.github.io/forgeops",
                        help='Helm repository to use')
    return parser


def run(args, config):
    """ Run the migration """

    msg = """
This script will help you migrate your secrets from secret-agent to
helm-secrets. Before continuing, make sure that your DS images have been
built with the ForgeOps 2025.3.0 release. This release includes a configuration
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
    * Upgrade to ForgeOps 2025.3.0
    * Deploy DS image with no downtime password rotation capability
        * Not required, but useful
        * Can use `forgeops build` in 2025.3.0 to build a new image
        * Must deploy the image after building

Would you like to continue? (Y/N)

"""

    print(msg)
    response = input()
    if response.lower().startswith('y'):
        print("Proceeding with migration.")
    else:
        print("Ok we will exit. Come back when you are ready.")
        sys.exit(0)

    pre_check(args, config)
    do_helm(args, config)

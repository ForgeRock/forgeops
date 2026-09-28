
#!/usr/bin/env python3
""" Apply a realm to a multipod deployment """

import argparse
from mergedeep import merge
from lib.python import utils, defaults
from lib.python.realm_common import apply_ldifs

KUBECTL = defaults.KUBECTL
ERR_STR = "ERROR!!"
WARN_STR = "WARNING!!"


def pre_check(params, settings):
    """ Check to make sure we are ready to go """
    print('Running pre-creation checks')
    is_problem = False
    settings['helm_env_path'] = settings['helm_path'] / params.env_name
    if params.debug:
        print(f"helm_env_path={settings['helm_env_path']}")
    helm_env_path = settings['helm_env_path']
    if utils.check_path(helm_env_path, 'Helm path', 'dir', True):
        print(f'Success! {helm_env_path} is a dir')
    else:
        print(f'{helm_env_path} is not a dir. Check --env-name and try again.')
        is_problem = True

    if is_problem:
        utils.exit_msg('Resolve issues listed above, and rerun the script.')
    else:
        print('No issues found. Continuing.')


def copy_images(params, settings):
    """ Copy images from the source env to the target env """
    if not getattr(params, 'source', None):
        print(f"Source env not given, not copying images.")
        return
    forgeops_cmd = settings['root_path'] / 'bin/forgeops'
    cmd_opts = f"image -e {params.env_name} -s {params.source} --copy"
    if getattr(params, 'helm_path', None):
        cmd_opts += f" -H {params.helm_path}"
    if getattr(params, 'kustomize_path', None):
        cmd_opts += f" -k {params.kustomize_path}"
    utils.run(forgeops_cmd, cmd_opts, debug=params.debug, dryrun=params.dryrun)


class ArgFormatter(argparse.ArgumentDefaultsHelpFormatter, argparse.RawDescriptionHelpFormatter):
    """ Setup an Argument Formatter """


def setup_args(subparsers, common_args):
    """ Setup arguments for forgeops realm create """

    prog = "forgeops realm apply"
    desc = "Apply a realm"
    epilog = f"""

  This command will apply a realm created with `forgeops realm create` to a
  multipod deployment. It copies the images from a source env to the target
  env, applies the ldif file to the DS pods, applies, the amster profile, and
  runs helm to deploy the images with the realm config on them.

  Notes:
    * New image deployment is Helm only.
    * Kustomize must deploy new images manually.

  Examples:
    Apply accounting realm:
    ./{prog} -s test-env-single -e test-env accounting

    Apply acct-recv (subrealm of accounting):
    ./{prog} -s test-env-single -e test-env acct-recv

    Apply multiple realms at once:
    ./{prog} -s test-env-single -e test-env accounting acct-recv

"""
    parser = subparsers.add_parser('apply',
                                   help=desc,
                                   prog=prog,
                                   epilog=epilog,
                                   parents=[common_args['debug'],
                                            common_args['dryrun'],
                                            common_args['env_name_req'],
                                            common_args['source_req'],
                                            common_args['helm_path'],
                                            common_args['kustomize_path'],
                                            common_args['namespace'],
                                            common_args['chart_name'],
                                            common_args['chart_version'],
                                            common_args['chart_repo']],
                                   formatter_class=ArgFormatter)
    parser.add_argument('realms', nargs='+', help='Name of realm to apply')
    return parser


def run(args, config):
    """ Apply the realm """

    config['namespace'] = utils.get_namespace(getattr(args, 'namespace', None))

    pre_check(args, config)
    for realm in args.realms:
        apply_ldifs(realm, config['namespace'], config['root_path'], args.debug, args.dryrun)
    copy_images(args, config)

    if utils.check_helm_installed():
        if utils.check_chart(config['namespace'], args.chart_name):
            values_f = config['helm_path'] / args.env_name / 'values.yaml'
            utils.run_helm_cmd(values_f,
                               config['namespace'],
                               dryrun=args.dryrun,
                               debug=args.debug,
                               chart_name=getattr(args, 'chart_name', None),
                               chart_repo=getattr(args, 'chart_repo', None),
                               chart_version=getattr(args, 'chart_version', None))

            for realm in args.realms:
                utils.apply_amster_profile(f"realm-{realm}", args.env_name, config['namespace'],
                                           config['root_path'], getattr(args, 'helm_path', None),
                                           getattr(args, 'kustomize_path', None),
                                           args.debug, args.dryrun)
        else:
            print(f"Could not find the {args.chart_name} Helm chart in {config['namespace']}. Not running helm.")
    else:
        print("Could not find the helm command. Not running helm.")

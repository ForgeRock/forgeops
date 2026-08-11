""" Common ForgeOps functions """

import argparse
import yaml


# Avoid using anchors/aliases in outputted YAML
# Notice we call this with yaml.dump, but we are still using safe_dump
# From https://ttl255.com/yaml-anchors-and-aliases-and-how-to-disable-them/
class NoAliasDumper(yaml.SafeDumper):
    """ A Dumper that doesn't use YAML aliases """
    def ignore_aliases(self, data):
        return True

def write_yaml_file(data, file, dryrun=False):
    """Write an object to a yaml file"""
    if dryrun:
        print(f"DRYRUN: Save YAML to {file}")
    else:
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

    env_help_msg = 'Forgeops environment to target'

    namespace_arg = argparse.ArgumentParser(add_help=False)
    namespace_arg.add_argument(
        '--namespace',
        '-n',
        help='Target namespace (default: current ctx namespace)')
    debug_arg = argparse.ArgumentParser(add_help=False)
    debug_arg.add_argument(
        '--debug',
        '-d',
        action='store_true',
        help='Turn on debugging')
    dryrun_arg = argparse.ArgumentParser(add_help=False)
    dryrun_arg.add_argument(
        '--dryrun',
        '-r',
        action='store_true',
        help='Do a dryrun')
    verbose_arg = argparse.ArgumentParser(add_help=False)
    verbose_arg.add_argument(
        '--verbose',
        '-v',
        action='store_true',
        help='Be verbose')
    config_profile_arg = argparse.ArgumentParser(add_help=False)
    config_profile_arg.add_argument(
        '--config-profile',
        '-p',
        help='Name of config profile in docker/<component>/config-profiles')
    env_name_arg = argparse.ArgumentParser(add_help=False)
    env_name_arg.add_argument(
        '--env-name',
        '-e',
        help=env_help_msg)
    env_name_arg_req = argparse.ArgumentParser(add_help=False)
    env_name_arg_req.add_argument(
        '--env-name',
        '-e',
        required=True,
        help=env_help_msg)
    build_path_arg = argparse.ArgumentParser(add_help=False)
    build_path_arg.add_argument(
        '--build-path',
        '-b',
        help='Path to build dir (absolute or relative to forgeops data dir) [default: docker]')
    helm_path_arg = argparse.ArgumentParser(add_help=False)
    helm_path_arg.add_argument(
        '--helm-path',
        '-H',
        help='Dir to store Helm values files (absolute or relative to forgeops data dir)')
    kustomize_path_arg = argparse.ArgumentParser(add_help=False)
    kustomize_path_arg.add_argument(
        '--kustomize-path',
        '-k',
        help='Kustomize dir to use (absolute or relative to forgeops data dir)')
    no_helm_arg = argparse.ArgumentParser(add_help=False)
    no_helm_arg.add_argument(
        '--no-helm',
        dest='no_helm',
        action='store_true',
        help="Skip Helm")
    no_kustomize_arg = argparse.ArgumentParser(add_help=False)
    no_kustomize_arg.add_argument(
        '--no-kustomize',
        dest='no_kustomize',
        action='store_true',
        help="Skip Kustomize")
    source_arg = argparse.ArgumentParser(add_help=False)
    source_arg.add_argument(
        '--source',
        '-s',
        help='Name of source Kustomize overlay')

    return {
        'debug': debug_arg,
        'dryrun': dryrun_arg,
        'verbose': verbose_arg,
        'namespace': namespace_arg,
        'config_profile': config_profile_arg,
        'env_name': env_name_arg,
        'env_name_req': env_name_arg_req,
        'build_path': build_path_arg,
        'helm_path': helm_path_arg,
        'kustomize_path': kustomize_path_arg,
        'no_helm': no_helm_arg,
        'no_kustomize': no_kustomize_arg,
        'source': source_arg,
    }

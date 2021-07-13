"""This is a shared lib used by other /bin python scripts"""

import subprocess
import shlex
import sys
import time
import json
import pathlib
from threading import Thread
import os
import shutil
import base64
import logging
import json
import re

CYAN = '\033[1;96m'
PURPLE = '\033[1;95m'
RED = '\033[1;91m'
ENDC = '\033[0m'
MSG_FMT = '[%(levelname)s] %(message)s'

_IGNORE_FILES = ('.DS_Store',)

log_name = 'foregops'

DOCKER_REGEX_NAME = {
    'am': '.*am',
    'amster' : '.*amster.*',
    'idm': '.*idm',
    'ds-idrepo': '.*ds-idrepo.*',
    'ds-cts': '.*ds-cts.*',
    'ig': '.*ig.*'
}

SCRIPT = pathlib.Path(__file__)
SCRIPT_DIR = SCRIPT.parent.resolve()
REPO_BASE_PATH = SCRIPT_DIR.joinpath('../').resolve()
DOCKER_BASE_PATH = REPO_BASE_PATH.joinpath('docker').resolve()
KUSTOMIZE_BASE_PATH = REPO_BASE_PATH.joinpath('kustomize').resolve()


class RunError(subprocess.CalledProcessError): pass

def loglevel(name):
    try:
        return getattr(logging, name.upper())
    except AttributeError:
        raise ValueError('Not a log level')

def add_loglevel_arg(parser):
    parser.add_argument('--log-level',
                    default='INFO',
                    type=loglevel)

class ColorFormatter(logging.Formatter):
    """Logging color"""
    FORMATS = {
        logging.DEBUG: f'{CYAN}{MSG_FMT}{ENDC}',
        logging.INFO: f'{CYAN}{MSG_FMT}{ENDC}',
        logging.WARNING: f'{PURPLE}{MSG_FMT}{ENDC}',
        logging.ERROR: f'{RED}{MSG_FMT}{ENDC}',
        logging.CRITICAL: f'{RED}{MSG_FMT}{ENDC}',
    }

    def format(self, record):
        log_fmt = self.FORMATS.get(record.levelno)
        formatter = logging.Formatter(log_fmt)
        formatter.datefmt = '%Y-%m-%dT%H:%M:%S%z'
        return formatter.format(record)


def logger(name=log_name, level=logging.INFO):
    handler = logging.StreamHandler(stream=sys.stdout)
    handler.setFormatter(ColorFormatter())
    handler.setLevel(level)

    log = logging.getLogger(name)
    log.addHandler(handler)
    log.setLevel(level)
    return log


def message(s):
    """Print info message"""
    print(f"{CYAN}{s}{ENDC}")


def error(s):
    """Print error message"""
    print(f"{RED}{s}{ENDC}")


def warning(s):
    """Print warning message"""
    print(f"{PURPLE}{s}{ENDC}")


def run(cmd, *cmdArgs, stdin=None, cstdout=False, cstderr=False, cwd=None, env=None):
    """rC runs a given command. Raises error if command returns non-zero code"""
    runcmd = f'{cmd} {" ".join(cmdArgs)}'
    stde_pipe = subprocess.PIPE if cstderr else None
    stdo_pipe = subprocess.PIPE if cstdout else None
    _r = subprocess.run(shlex.split(runcmd), stdout=stdo_pipe, stderr=stde_pipe,
                        check=True, input=stdin, cwd=cwd, env=env)
    return _r.returncode == 0, _r.stdout, _r.stderr


def _waitforsecret(ns, secret_name):
    print(f'Waiting for secret: {secret_name} .', end='')
    sys.stdout.flush()
    while True:
        try:
            run('kubectl', f'-n {ns} get secret {secret_name}',
                cstderr=True, cstdout=True)
            print('done')
            break
        except Exception as _:
            print('.', end='')
            sys.stdout.flush()
            time.sleep(1)
            continue

def _waitfords(ns, ds_name):
    print(f'Waiting for Service Account Password Update: .', end='')
    sys.stdout.flush()
    while True:
        try:
            _, valuestr, _ = run('kubectl', f'-n {ns} get directoryservices.directory.forgerock.io {ds_name} -o jsonpath={{.status.serviceAccountPasswordsUpdatedTime}}',
                             cstderr=True, cstdout=True)
            if len(valuestr) > 0:
                print('done')
                break
            raise("DS not ready")
        except Exception as _:
            print('.', end='')
            sys.stdout.flush()
            time.sleep(1)
            continue

def _runwithtimeout(target, args, secs):
    t = Thread(target=target, args=args)
    t.start()
    t.join(timeout=secs)
    if t.is_alive():
        print(f'{target} timed out after {secs} secs')
        sys.exit(1)

def waitforsecrets(ns):
    """Wait for the given secrets to exist in the Kubernetes api."""
    secrets = ['am-env-secrets', 'idm-env-secrets',
               'rcs-agent-env-secrets', 'ds-passwords', 'ds-env-secrets']
    message('\nWaiting for K8s secrets')
    for secret in secrets:
        _runwithtimeout(_waitforsecret, [ns, secret], 60)

def wait_for_ds(ns, directoryservices_name):
    """Wait for DS pods to be ready after ds-operator deployment"""
    run('kubectl', f'-n {ns} rollout status --watch statefulset {directoryservices_name} --timeout=300s')
    _runwithtimeout(_waitfords, [ns, directoryservices_name], 120)

def getsec(ns, secret, secretKey):
    """Get secret contents"""
    _, pipe, _ = run('kubectl',
                     f'-n {ns} get secret {secret} -o jsonpath={{.data.{secretKey}}}', cstdout=True)
    _, pipe, _ = run('base64', '--decode', cstdout=True, stdin=pipe)
    return pipe.decode('ascii')

def printsecrets(ns):
    """Print relevant platform secrets"""
    message('\nRelevant passwords:')
    try:
        print(
            f"{getsec(ns, 'am-env-secrets', 'AM_PASSWORDS_AMADMIN_CLEAR')} (amadmin user)")
        print(
            f"{getsec(ns, 'idm-env-secrets', 'OPENIDM_ADMIN_PASSWORD')} (openidm-admin user)")
        print(
            f"{getsec(ns, 'rcs-agent-env-secrets', 'AGENT_IDM_SECRET')} (rcs-agent IDM secret)")
        print(
            f"{getsec(ns, 'rcs-agent-env-secrets', 'AGENT_RCS_SECRET')} (rcs-agent RCS secret)")
        print("{} (uid=admin user)".format(getsec(ns, 'ds-passwords',
              'dirmanager\\.pw')))  # f'strings' do not allow '\'
        print(f"{getsec(ns, 'ds-env-secrets', 'AM_STORES_APPLICATION_PASSWORD')} (App str svc acct (uid=am-config,ou=admins,ou=am-config))")
        print(f"{getsec(ns, 'ds-env-secrets', 'AM_STORES_CTS_PASSWORD')} (CTS svc acct (uid=openam_cts,ou=admins,ou=famrecords,ou=openam-session,ou=tokens))")
        print(f"{getsec(ns, 'ds-env-secrets', 'AM_STORES_USER_PASSWORD')} (ID repo svc acct (uid=am-identity-bind-account,ou=admins,ou=identities))")
    except Exception as _e:
        sys.exit(1)


def printurls(ns):
    """Print relevant platform URLs"""
    message('\nRelevant URLs:')
    _, fqdn, _ = run(
        'kubectl', f'-n {ns} get ingress forgerock -o jsonpath={{.spec.rules[0].host}}', cstdout=True)
    fqdn = fqdn.decode('ascii')
    warning(f'https://{fqdn}/platform')
    warning(f'https://{fqdn}/admin')
    warning(f'https://{fqdn}/am')
    warning(f'https://{fqdn}/enduser')

def install_dependencies():
    """Check and install dependencies"""
    print('Checking secret-agent operator and related CRDs:', end=' ')
    try:
        run('kubectl', 'get crd secretagentconfigurations.secret-agent.secrets.forgerock.io',
                  cstderr=True, cstdout=True)
    except Exception as _e:
        warning('secret-agent CRD not found. Installing secret-agent.')
        secretagent('apply')
    else:
        message('secret-agent CRD found in cluster.')

    print('Checking ds-operator and related CRDs:', end=' ')
    try:
        run('kubectl', 'get crd directoryservices.directory.forgerock.io', cstderr=True, cstdout=True)
    except Exception:
        warning('ds-operator CRD not found. Installing ds-operator.')
        dsoperator('apply')
    else:
        message('ds-operator CRD found in cluster.')
    print()

def secretagent(k8s_op, tag='latest'):
    """Check and install secret-agent"""
    opts = ''
    if k8s_op == 'delete':
        opts = '--ignore-not-found=true'
    if tag == 'latest':
        run('kubectl',
            f'{k8s_op} -f https://github.com/ForgeRock/secret-agent/releases/latest/download/secret-agent.yaml {opts}')
    else:
        run('kubectl',
            f'{k8s_op} -f https://github.com/ForgeRock/secret-agent/releases/download/{tag}/secret-agent.yaml {opts}')
    if k8s_op == 'apply':
        message('\nWaiting for secret agent operator...')
        time.sleep(5)
        run('kubectl', 'wait --for=condition=Established crd secretagentconfigurations.secret-agent.secrets.forgerock.io --timeout=30s')
        run('kubectl', '-n secret-agent-system wait --for=condition=available deployment  --all --timeout=120s')
        run('kubectl', '-n secret-agent-system wait --for=condition=ready pod --all --timeout=120s')
        print()


def dsoperator(k8s_op, tag='latest'):
    """Check and install ds-operator"""
    opts = ''
    if k8s_op == 'delete':
        opts = '--ignore-not-found=true'
    if tag == 'latest':
        run('kubectl',
            f'{k8s_op} -f https://github.com/ForgeRock/ds-operator/releases/latest/download/ds-operator.yaml {opts}')
    else:
        run('kubectl',
            f'{k8s_op} -f https://github.com/ForgeRock/ds-operator/releases/download/{tag}/ds-operator.yaml {opts}')

    if k8s_op == 'apply':
        message('\nWaiting for ds-operator...')
        time.sleep(5)
        run('kubectl', 'wait --for=condition=Established crd directoryservices.directory.forgerock.io --timeout=30s')
        run('kubectl', '-n fr-system wait --for=condition=available deployment  --all --timeout=120s')
        run('kubectl', '-n fr-system wait --for=condition=ready pod --all --timeout=120s')

def build_docker_image(component, default_repo, tag, config_profile=None):
    """Builds custom docker images. Returns the tag of the built image"""
    # Clean out the temp kustomize files
    base_dir = os.path.join(sys.path[0], '../')

    if default_repo:
        default_repo_cmd = f'--default-repo={default_repo}'
    else:
        default_repo_cmd = ''
    if tag:
        tag_cmd = f'--tag={tag}'
    else:
        tag_cmd = ''

    envVars = None
    if config_profile:
        envVars = os.environ
        envVars['CONFIG_PROFILE'] = str(config_profile)
    run('skaffold', f'build -p {component} --file-output=tag.json {default_repo_cmd} {tag_cmd}', cwd=base_dir, env=envVars)
    with open(os.path.join(base_dir, 'tag.json')) as tag_file:
        tag_data = json.load(tag_file)['builds'][0]["tag"]
    return tag_data

def clone_pipeline_images(clone_path,
                          branch_name='master',
                          repo='ssh://git@stash.forgerock.org:7999/cloud/platform-images.git'):
    """
    Clone pipeline images and checkout branch to the given path.
    Raise exception if not succesful
    """
    path = pathlib.Path(clone_path)
    # check for emptydir
    if any(path.glob('*')):
        print('Found existing files, not cloning')
        return
    status, out, err = run('git',
                           'clone',
                           '--depth', '1',
                           '--branch',
                           branch_name,
                           repo,
                           str(path))
    if not status:
        print(err)
        raise IOError(err)

_USER_PWD_EXPR_RULES = {
    'idm-provisioning.json': '&{idm.provisioning.client.secret|openidm}',
    'idm-resource-server.json': '&{idm.rs.client.secret|password}',
    'resource-server.json': '&{ig.rs.client.secret|password}',
    'oauth2.json': '&{pit.client.secret|password}',
    'ig-agent.json': '&{ig.agent.password|password}',
}
ALLOWED_COMMONS_CHARS = re.compile(r'[^A-Za-z0-9\s\..]+')

def _convert_path_to_common_exp(path):
    """
    This changes:
      docker/amster/foo/conf/realms/root-philA/OAuth2Clients/b.json
      realms.rootphilA.oauth2clients.b.userpassword
    """
    path_parts = path.parent.parts
    start = path_parts.index('config')
    dotted_path = '.'.join(path_parts[start + 1:])
    safe_path = ALLOWED_COMMONS_CHARS.sub('', dotted_path)
    safe_name = ALLOWED_COMMONS_CHARS.sub('', path.stem)
    return f'&{{{safe_path}.{safe_name}.userpassword}}'


def upgrade_amster_conf(conf, conf_file_name, fqdn):
    """
    Recursively search objects looking at values and keys that need
    to be updated.
    """
    log = logging.getLogger('forgeops')
    # Go through all items in a list
    if isinstance(conf, list):
        for i in conf:
            conf = upgrade_amster_conf(i, conf_file_name, fqdn)
        return conf
    # This is str, int, bool, float and nulls we don't do anything with these
    # types.
    elif not isinstance(conf, dict):
        return conf

    # use copy to iterate through so we can modify keys.
    for k, v in conf.copy().items():
        if isinstance(v, dict):
            conf[k] = upgrade_amster_conf(v, conf_file_name, fqdn)
            continue
        elif isinstance(v, list):
            new_value = []
            for i in v:
                new_value.append(upgrade_amster_conf(v, conf_file_name, fqdn))
            conf[k] = new_value
            continue
        # Update FQDN
        try:
            if fqdn in v:
                log.debug('Found a fqdn entry, updating.')
                conf[k] = v.replace(fqdn(), '&{fqdn}')
        except TypeError:
            # this happens if there's value of none.
            pass
        # Key based updates
        # userpassword, amsterVersion, userpassword-encrypted
        if k == 'userpassword-encrypted':
            conf.pop(k)
        # TODO this has two external things that need to be ported...
        elif k == 'userpassword':
            try:
                conf[k] = _USER_PWD_EXPR_RULES[conf_file_name.name]
                # log.debug(f'Updated {conf_file_name.name}')
            except KeyError:
                log.info(
                     (f'A userpassword key found in {conf_file_name} '
                      'but no replacement rule was found, using default'))
                conf[k] = _convert_path_to_common_exp(conf_file_name)
                log.info(f'{conf_file_name} has password changed to {conf[k]}')
        # update amster version
        elif k == 'amsterVersion':
            conf[k] = '&{version}'
    return conf


def sort_dir_json(base):
    """
    Recursively search a path for json files. Round-tripping to sort alpha
    numerically.
    """
    conf_base = pathlib.Path(base).resolve()
    if not conf_base.is_dir():
        raise NotADirectoryError(f'{conf_base} is not a directory')
    for conf_file in conf_base.rglob('**/*.json'):
        with conf_file.open('r+') as fp:
            conf = json.load(fp)
            fp.seek(0)
            fp.truncate()
            json.dump(conf, fp, sort_keys=True, indent=2)


def copytree(src, dst):
    """
    A simple version of 3.7+ shutil.copytree for 3.6.
    No metadata.
    No links.
    Captures all errors and concats to a string.
    """
    errors = []
    for src_entry in os.scandir(src):
        try:
            if src_entry.name in _IGNORE_FILES:
                continue
            os.makedirs(dst, exist_ok=True)
            src_name = os.path.join(src, src_entry.name)
            dst_name = os.path.join(dst, src_entry.name)
            if src_entry.is_file():
                shutil.copyfile(src_name, dst_name)
            elif src_entry.is_symlink():
                raise IOError(f'Symlinks not supported {src_entry.path}')
            elif src_entry.is_dir():
                copytree(src_name, dst_name)
        except Exception as e:
            errors.extend(str(e))

    if errors:
        raise Exception('\n'.join(errors))

# Run kubectl. If verbose is true, echo the command to the stdout
# Returns the output as a string
# def kubectl(cmd,verbose=True ):
#      args = f'kubectl {namespace} {command}'
#     print(args)
#     r = subprocess.run(args.split())
#     return r.returncode


# IF ns is not None, then return it, otherwise lookup the current namespace context
def get_namespace(ns):
    if ns != None:
        return ns

    r = subprocess.run(f"kubectl config view --minify --output jsonpath='{{..namespace}}'", shell=True, capture_output=True)
    if r.returncode != 0:
        print(f'Can not not run kubectl to get the current namespace {r.stderr} : {r.stdout}')
        sys.exit(1)
    return r.stdout.decode("utf-8")

# Lookup the value of a configmap key
def get_configmap_value(namespace, configmap, key):
    ks = "{.data." + key + "}"
    r = subprocess.run(f'kubectl --namespace {namespace} get configmap {configmap} -o jsonpath={ks}', shell=True, capture_output=True)
    if r.returncode != 0:
        print(f'Kubectl error {r.stderr} : {r.stdout}')
        sys.exit(1)
    return r.stdout.decode("utf-8")


# Lookup the value of a secret
def get_secret_value(namespace, secret, key):
    ks = "{.data." + key + "}"
    r = subprocess.run(f'kubectl --namespace {namespace} get secret {secret} -o jsonpath={ks}', shell=True, capture_output=True)
    if r.returncode != 0:
        print(f'Kubectl error {r.stderr} : {r.stdout}')
        sys.exit(1)

         # base64 decode the secret
    secret = base64.b64decode(r.stdout.decode("utf-8"))
    return secret

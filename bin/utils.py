"""This is a shared lib used by other /bin python scripts"""

import subprocess
import sys
import time
import pathlib
from threading import Thread
import os
import shutil
import pkg_resources
import base64
import re

CYAN = '\033[1;96m'
PURPLE = '\033[1;95m'
RED = '\033[1;91m'
ENDC = '\033[0m'

_IGNORE_FILES = ('.DS_Store',)

ALLOWED_COMMONS_CHARS = re.compile(r'[^A-Za-z0-9\s\..]+')

REQ_VERSIONS ={
    'ds-operator': {
        'MIN': 'v0.0.8',
        'MAX': 'v0.0.8',
    },
    'secret-agent': {
        'MIN': 'v1.0.5',
        'MAX': 'v100',
    },
    'minikube': {
        'MIN': 'v1.22.0',
        'MAX': 'v100',
    }
}

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
    _r = subprocess.run(runcmd.split(), stdout=stdo_pipe, stderr=stde_pipe,
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

def printsecrets(ns):
    """Print relevant platform secrets"""
    message('\nRelevant passwords:')
    try:
        print(
            f"{get_secret_value(ns, 'am-env-secrets', 'AM_PASSWORDS_AMADMIN_CLEAR')} (amadmin user)")
        print(
            f"{get_secret_value(ns, 'idm-env-secrets', 'OPENIDM_ADMIN_PASSWORD')} (openidm-admin user)")
        print(
            f"{get_secret_value(ns, 'rcs-agent-env-secrets', 'AGENT_IDM_SECRET')} (rcs-agent IDM secret)")
        print(
            f"{get_secret_value(ns, 'rcs-agent-env-secrets', 'AGENT_RCS_SECRET')} (rcs-agent RCS secret)")
        print("{} (uid=admin user)".format(get_secret_value(ns, 'ds-passwords',
              'dirmanager\\.pw')))  # f'strings' do not allow '\'
        print(f"{get_secret_value(ns, 'ds-env-secrets', 'AM_STORES_APPLICATION_PASSWORD')} (App str svc acct (uid=am-config,ou=admins,ou=am-config))")
        print(f"{get_secret_value(ns, 'ds-env-secrets', 'AM_STORES_CTS_PASSWORD')} (CTS svc acct (uid=openam_cts,ou=admins,ou=famrecords,ou=openam-session,ou=tokens))")
        print(f"{get_secret_value(ns, 'ds-env-secrets', 'AM_STORES_USER_PASSWORD')} (ID repo svc acct (uid=am-identity-bind-account,ou=admins,ou=identities))")
    except Exception as _e:
        sys.exit(1)


def printurls(ns):
    """Print relevant platform URLs"""
    fqdn = get_fqdn(ns)
    message('\nRelevant URLs:')
    warning(f'https://{fqdn}/platform')
    warning(f'https://{fqdn}/admin')
    warning(f'https://{fqdn}/am')
    warning(f'https://{fqdn}/enduser')


def check_component_version(component, version):

    version = pkg_resources.parse_version(version)
    version_max = pkg_resources.parse_version(REQ_VERSIONS[component]['MAX'])
    version_min = pkg_resources.parse_version(REQ_VERSIONS[component]['MIN'])
    if not version_min <= version <= version_max:
        error(f'Unsupported {component} version found: "{version}"')
        message(f'Need {component} versions: {version_min} <= X <= {version_max}')
        sys.exit(1)

def install_dependencies():
    """Check and install dependencies"""
    print('Checking secret-agent operator and related CRDs:', end=' ')
    try:
        run('kubectl', 'get crd secretagentconfigurations.secret-agent.secrets.forgerock.io',
            cstderr=True, cstdout=True)
    except Exception as _e:
        warning('secret-agent CRD not found. Installing secret-agent.')
        secretagent('apply', tag='v1.0.5')
    else:
        message('secret-agent CRD found in cluster.')

    _, img, _= run('kubectl', f'-n secret-agent-system get deployment secret-agent-controller-manager -o jsonpath={{.spec.template.spec.containers[0].image}}',
        cstderr=True, cstdout=True)
    check_component_version('secret-agent', img.decode('utf-8').split(':')[1])

    print('Checking ds-operator and related CRDs:', end=' ')
    try:
        run('kubectl', 'get crd directoryservices.directory.forgerock.io',
            cstderr=True, cstdout=True)
    except Exception:
        warning('ds-operator CRD not found. Installing ds-operator.')
        dsoperator('apply', tag='v0.0.8')
    else:
        message('ds-operator CRD found in cluster.')

    _, img, _= run('kubectl', f'-n fr-system get deployment ds-operator-ds-operator -o jsonpath={{.spec.template.spec.containers[0].image}}',
        cstderr=True, cstdout=True)
    check_component_version('ds-operator', img.decode('utf-8').split(':')[1])
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

def get_fqdn(ns):
    _, fqdn, _ = run(
        'kubectl', f'-n {ns} get ingress forgerock -o jsonpath={{.spec.rules[0].host}}', cstdout=True)
    return fqdn.decode('utf-8')

# IF ns is not None, then return it, otherwise lookup the current namespace context
def get_namespace(ns=None):
    if ns != None:
        return ns
    _, ctx_namespace, _ = run('kubectl', 'config view --minify --output=jsonpath={..namespace}', cstdout=True)
    return ctx_namespace.decode('utf-8') if ctx_namespace else 'default'

def get_context():
    _, ctx, _ = run('kubectl', 'config view --minify --output=jsonpath={..current-context}', cstdout=True)
    return ctx.decode('utf-8') if ctx else 'default'

# Lookup the value of a configmap key
def get_configmap_value(ns, configmap, key):
    """Get configmap contents"""
    _, value, _ = run('kubectl',
                     f'-n {ns} get configmap {configmap} -o jsonpath={{.data.{key}}}', cstdout=True)
    return value.decode('utf-8')

# Lookup the value of a secret
def get_secret_value(ns, secret, key):
    """Get secret contents"""
    _, value, _ = run('kubectl',
                     f'-n {ns} get secret {secret} -o jsonpath={{.data.{key}}}', cstdout=True)
    return base64.b64decode(value).decode('utf-8')
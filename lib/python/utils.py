"""This is a shared lib used by other /bin python scripts"""

import subprocess
import shlex
import sys
import time
import pathlib
from threading import Thread
import os
import shutil
import base64
import logging
import json
import re
import site
from pathlib import Path
file_name = Path(__file__)
current_file_path = file_name.parent.resolve()
root_path = [parent_path for parent_path in current_file_path.parents if (parent_path / 'README.md').exists()][0]
dependencies_dir = os.path.join(root_path, 'lib', 'dependencies')
# Insert lib folders to python path
sys.path.insert(0, str(root_path))
sys.path.insert(1, str(dependencies_dir) + site.USER_SITE.replace(site.USER_BASE, ''))

from lib.python.defaults import RELEASES_SRC_DEF, ENV_COMPONENTS_VALID

CYAN = '\033[1;96m'
PURPLE = '\033[1;95m'
BLUE = '\033[1;94m'
RED = '\033[1;91m'
ENDC = '\033[0m'
MSG_FMT = '[%(levelname)s] %(message)s'

log_name = 'forgeops'

ALLOWED_COMMONS_CHARS = re.compile(r'[^A-Za-z0-9\s\..]+')

REQ_VERSIONS ={
    'secret-agent': {
        'MIN': 'v1.1.5',
        'MAX': 'v100.0.0',
        'DEFAULT': 'latest',
    },
    'cert-manager': {
        'MIN': 'v1.5.1',
        'MAX': 'v100.0.0',
        'DEFAULT': 'latest',
    },
    'minikube': {
        'MIN': 'v1.22.0',
        'MAX': 'v100.0.0',
    },
    'kubectl': {
        'MIN': 'v1.20.0',
        'MAX': 'v100.0.0',
    },
    'kubernetes':{
        'MIN':'v1.19.1',
        'MAX':'v100.0.0',
    },
    'kustomize': {
        'MIN': 'v4.2.0',
        'MAX': 'v100.0.0',
    },
}

SCRIPT_DIR = pathlib.Path(os.path.join(root_path, 'bin'))
REPO_BASE_PATH = SCRIPT_DIR.joinpath('../').resolve()
DOCKER_BASE_PATH = REPO_BASE_PATH.joinpath('docker').resolve()
KUSTOMIZE_BASE_PATH = REPO_BASE_PATH.joinpath('kustomize').resolve()
RULES_PATH = REPO_BASE_PATH.joinpath("etc/am-upgrader-rules").resolve()

class RunError(subprocess.CalledProcessError):
    pass

def loglevel(name):
    try:
        return getattr(logging, name.upper())
    except AttributeError:
        raise ValueError('Not a log level')

def add_loglevel_arg(parser):
    parser.add_argument('--log-level',
                        default='INFO',
                        type=loglevel)

def exit_msg(msg, code=1):
    """Exit script with error code and message"""
    print(f'ERROR: {msg}')
    sys.exit(code)

class NoColorFormatter(logging.Formatter):
    """Logging with no color"""
    NON_TTY_FORMATS = {
        logging.DEBUG: f'{MSG_FMT}',
        logging.INFO: f'{MSG_FMT}',
        logging.WARNING: f'{MSG_FMT}',
        logging.ERROR: f'{MSG_FMT}',
        logging.CRITICAL: f'{MSG_FMT}',
    }

    def format(self, record):
        log_fmt = self.NON_TTY_FORMATS.get(record.levelno)
        formatter = logging.Formatter(log_fmt)
        formatter.datefmt = '%Y-%m-%dT%H:%M:%S%z'
        return formatter.format(record)

class ColorFormatter(logging.Formatter):
    """Logging color"""
    TTY_FORMATS = {
        logging.DEBUG: f'{BLUE}{MSG_FMT}{ENDC}',
        logging.INFO: f'{CYAN}{MSG_FMT}{ENDC}',
        logging.WARNING: f'{PURPLE}{MSG_FMT}{ENDC}',
        logging.ERROR: f'{RED}{MSG_FMT}{ENDC}',
        logging.CRITICAL: f'{RED}{MSG_FMT}{ENDC}',
    }

    def format(self, record):
        log_fmt = self.TTY_FORMATS.get(record.levelno)
        formatter = logging.Formatter(log_fmt)
        formatter.datefmt = '%Y-%m-%dT%H:%M:%S%z'
        return formatter.format(record)

def logger(name=log_name, level=logging.INFO):
    log = logging.getLogger(name)
    # Clear any current loggers
    if (log.hasHandlers()):
        log.handlers.clear()

    handler = logging.StreamHandler(stream=sys.stdout)
    if not sys.stdout.isatty():
        log_cls = NoColorFormatter()
    else:
        log_cls = ColorFormatter()
    handler.setFormatter(log_cls)
    handler.setLevel(level)
    log.addHandler(handler)
    log.setLevel(level)
    return log

log = logger(log_name)

def message(s):
    """Print info message"""
    print(f"{CYAN}{s}{ENDC}")

def error(s):
    """Print error message"""
    print(f"{RED}{s}{ENDC}")

def warning(s):
    """Print warning message"""
    print(f"{PURPLE}{s}{ENDC}")

def sub_title(title):
    total_length = 100
    spacing_length = 3 if len(title) > 0 else 0
    total_length -= 2 * spacing_length
    total_length -= len(title)
    if total_length < 0:
        warning(f'title "{title}" is too long')
    one_more = total_length % 2
    separator_char = '-'
    separator_count = int(total_length / 2)
    first_part = separator_count * separator_char + (spacing_length + one_more) * ' '
    second_part = spacing_length * ' ' + separator_count * separator_char
    msg = first_part + str(title) + second_part
    print('')
    print(msg)

def run(cmd, *cmdArgs, stdin=None, cstdout=False, cstderr=False, cwd=None, env=None, ignoreFail=False):
    """
    Execute the given command. Raises error if command returns non-zero code.
    cmd: command to run.
    cmdArgs: arguments of the command. Can be a single string containing all args or multiple strings comma separated (one arg each).
    stdin: stdin to pass the command during runtime. Useful to pipe the output of one command to another.
    cstdout: set to True to capture stdout of the cmd. If set to False, stdout is printed to console.
    cstderr: set to True to capture stderr of the cmd. If set to False, stderr is printed to console.
    cwd: change working directory to this path during runtime.
    env: dictionary containing environment variables to pass during runtime.
    ignoreFail: if True, do not raise an exception if the cmd fails.
    return: success, stdout, stderr. stdout and stderr are only populated if cstdout and cstderr are True.
    """
    runcmd = f'{cmd} {" ".join(cmdArgs)}'
    stde_pipe = subprocess.PIPE if cstderr else None
    stdo_pipe = subprocess.PIPE if cstdout else None
    log.debug(f'Running: "{runcmd}"' + (f' in CWD="{os.path.abspath(cwd)}"' if cwd else ''))
    try:
        _r = subprocess.run(shlex.split(runcmd), stdout=stdo_pipe, stderr=stde_pipe,
                            check=True, input=stdin, cwd=cwd, env=env)
        return _r.returncode == 0, _r.stdout, _r.stderr
    except Exception as e:
        if ignoreFail:
            return False, None, None
        raise(e)

def run_condfail(cmd, *cmdArgs, stdin=None, cstdout=False, cstderr=False, cwd=None, env=None, ignoreFail=False):
    """Wrapper function for run() that ignores failures if selected."""
    try:
        _, rstdout, rstderr = run(cmd, *cmdArgs, stdin=stdin, cstdout=cstdout, cstderr=cstderr, cwd=cwd, env=env)
        return True, rstdout, rstderr
    except Exception as e:
        if ignoreFail:
            return False, None, None
        raise(e)

def _waitforresource(ns, resource_type, resource_name):
    """
    Wait for a resource to exist in the k8s api. This is a blocking call with no timeout.
    resource_type: k8s resource type. e.a. pod, secret, deployment.
    resource_name: k8s resource name.
    """
    print(f'Waiting for {resource_type} "{resource_name}" to exist in the cluster: ', end='')
    sys.stdout.flush()
    while True:
        try:
            run('kubectl', f'-n {ns} get {resource_type} {resource_name}',
                cstderr=True, cstdout=True)
            print('done')
            break
        except Exception as _:
            print('.', end='')
            sys.stdout.flush()
            time.sleep(1)
            continue

def _runwithtimeout(target, args, secs):
    """
    Run a function with a timeout. If timeout is reached, exit program.
    target: target function to run.
    args: list of positional arguments passed to the target function.
    secs: timeout in seconds.
    """
    t = Thread(target=target, args=args, daemon=True)
    t.start()
    t.join(timeout=secs)
    if t.is_alive():
        print(f'{target} timed out after {secs} secs')
        sys.exit(1)

def printsecrets(ns, to_stdout=True):
    """
    Obtain and print platform secrets.
    ns: target namespace.
    to_stdout: set to true to print secrets to stdout. If false, secrets will not be printed.
    return secrets: Dictionary containing the platform secrets. Secrets are returned even if to_stdout is set to False.
    """
    try:
        secrets = {
            'am-env-secrets': {
                'AM_PASSWORDS_AMADMIN_CLEAR': None
            },
            'ds-passwords': {
                'dirmanager\\\\.pw': None,
            },
            'ds-env-secrets': {
                'AM_STORES_APPLICATION_PASSWORD': None,
                'AM_STORES_CTS_PASSWORD': None,
                'AM_STORES_USER_PASSWORD': None,
            },
        }
        for secret in secrets:
            for key in secrets[secret]:
                secrets[secret][key] = get_secret_value(ns, secret, key)
        if to_stdout:
            message('\nRelevant passwords:')
            print(
                f"{secrets['am-env-secrets']['AM_PASSWORDS_AMADMIN_CLEAR']} (amadmin user)")
            print("{} (uid=admin user)".format(secrets['ds-passwords']['dirmanager\\\\.pw']))  # f'strings' do not allow '\'
            print(f"{secrets['ds-env-secrets']['AM_STORES_APPLICATION_PASSWORD']} (App str svc acct (uid=am-config,ou=admins,ou=am-config))")
            print(f"{secrets['ds-env-secrets']['AM_STORES_CTS_PASSWORD']} (CTS svc acct (uid=openam_cts,ou=admins,ou=famrecords,ou=openam-session,ou=tokens))")
            print(f"{secrets['ds-env-secrets']['AM_STORES_USER_PASSWORD']} (ID repo svc acct (uid=am-identity-bind-account,ou=admins,ou=identities))")
        return secrets
    except Exception as _e:
        sys.exit(1)

def printurls(ns, to_stdout=True):
    """
    Calculate and print relevant platform URLs.
    ns: target namespace.
    to_stdout: set to true to print URLs to stdout. If false, URLs will not be printed.
    return secrets: dictionary containing the URLs. URLs are returned even if to_stdout is set to False.
    """
    fqdn = get_fqdn(ns)
    urls = {
        'platform': f'https://{fqdn}/platform',
        'idm': f'https://{fqdn}/admin',
        'am': f'https://{fqdn}/am',
        'enduser': f'https://{fqdn}/enduser',
    }
    if to_stdout:
        message('\nRelevant URLs:')
        for url in urls:
            print(urls[url])
    return urls

def secretagent(k8s_op, tag='latest'):
    """Check if secret-agent is present in the cluster. If not, installs it."""
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

def _install_certmanager_issuer():
    """Install certmanager self-signed issuer. This works as a placeholder issuer."""
    addons_dir = os.path.join(root_path, 'cluster', 'addons', 'certmanager')
    issuer = os.path.join(addons_dir, 'files', 'selfsigned-issuer.yaml')
    print('\nInstalling cert-manager\'s self-signed issuer: ', end='')
    sys.stdout.flush()
    while True:
        try:
            time.sleep(5)
            print('.', end='')
            sys.stdout.flush()
            _, res, _ = run('kubectl', f'-n cert-manager apply -f {issuer}', cstderr=True, cstdout=True)
            print('Done.')
            print(res.decode('utf-8'))
            break
        except:
            continue

def certmanager(k8s_op, tag='latest'):
    """Check if cert-manager is present in the cluster. If not, installs it."""
    opts = ''
    if k8s_op == 'delete':
        opts = '--ignore-not-found=true'
    if tag == 'latest':
        component_url = 'https://github.com/jetstack/cert-manager/releases/latest/download/cert-manager.yaml'
        run('kubectl',
            f'{k8s_op} -f https://github.com/jetstack/cert-manager/releases/latest/download/cert-manager.crds.yaml {opts}')
    else:
        component_url = f'https://github.com/jetstack/cert-manager/releases/download/{tag}/cert-manager.yaml'
        run('kubectl',
            f'{k8s_op} -f https://github.com/jetstack/cert-manager/releases/download/{tag}/cert-manager.crds.yaml {opts}')

    if k8s_op == 'apply':
        message('\nWaiting for cert-manager CRD registration...')
        time.sleep(5)
        run('kubectl', 'wait --for=condition=Established crd certificaterequests.cert-manager.io --timeout=60s')
        run('kubectl', 'wait --for=condition=Established crd certificates.cert-manager.io --timeout=60s')
        run('kubectl', 'wait --for=condition=Established crd clusterissuers.cert-manager.io --timeout=60s')

    run('kubectl', f'{k8s_op} -f {component_url} {opts}')

    if k8s_op == 'apply':
        message('\nWaiting for cert-manager pods...')
        run('kubectl', '-n cert-manager wait --for=condition=available deployment  --all --timeout=300s')
        run('kubectl', '-n cert-manager wait --for=condition=ready pod --all --timeout=300s')
        _runwithtimeout(_install_certmanager_issuer, [], 180)

def configure_platform_images(clone_path,
                              ref='',
                              repo='ssh://git@stash.forgerock.org:7999/cloud/platform-images.git'):
    """
    Clone platform images and checkout branch to the given path.
    Raise exception if not succesful.
    """
    log = logger()
    path = pathlib.Path(clone_path)

    def grun(*args, **kwargs):
        run('git', '-C', str(path), *args, cstdout=True, cstderr=True)

    git_dir = path.joinpath('.git')
    # handle existing config directory
    if git_dir.is_dir() and ref != '':
        log.info('Found existing files, attempting to not clone.')
        try:
            # capture stdout and stderr so git doesn't write to log
            run('git', '-C', str(path), 'checkout',
                ref, cstdout=True, cstderr=True)
            return
        except:
            log.error('Couldn\'t find reference. Getting fresh clone.')
            shutil.rmtree(str(path))
    elif git_dir.is_dir():
        log.info('Using existing repo, remove it to get a fresh clone.')
        return
    # some path that's not a git repo so don't do anything.
    elif any(path.glob('*')) and not git_dir.is_dir():
        raise Exception('Found existing directory that is not a git repo.')
    try:
        if ref != '':
            # initialize repo
            run('git', 'init', str(path), cstdout=True, cstderr=True)
            # add remote
            grun('remote', 'add', 'origin', repo)
            grun('config', '--add', 'remote.origin.fetch',
                 '+refs/pull-requests/*/from:refs/remotes/origin/pr/*')
            # checkout
            grun('fetch', 'origin')
            grun('checkout', ref)
        else:
            # shallow setup
            run('git', 'clone', '--depth', '1', repo,
                str(path), cstdout=True, cstderr=True)
    except RunError as e:
        log.error(f'Couldn\'t configure repo running {e.cmd} {e.output}.')
        raise e
    except Exception as e:
        log.error(f'Couldn\t configure repo {e}.')
        raise e

def sort_dir_json(base):
    """
    Recursively search a path for json files. Round-tripping to sort alpha.
    numerically.
    """
    conf_base = pathlib.Path(base).resolve()
    if not conf_base.is_dir():
        raise NotADirectoryError(f'{conf_base} is not a directory.')
    for conf_file in conf_base.rglob('**/*.json'):
        with conf_file.open('r+') as fp:
            conf = json.load(fp)
            fp.seek(0)
            fp.truncate()
            json.dump(conf, fp, sort_keys=True, indent=2)


# Run kubectl. If verbose is true, echo the command to the stdout
# Returns the output as a string
# def kubectl(cmd,verbose=True ):
#      args = f'kubectl {namespace} {command}'
#     print(args)
#     r = subprocess.run(args.split())
#     return r.returncode

def get_fqdn(ns):
    """Get the FQDN of the deployment. This is obtained directly from the ingress definition"""
    try:
        _, ingress_name, _ = run(
            'kubectl', f'-n {ns} get ingress -o jsonpath={{.items[0].metadata.name}}', cstdout=True, cstderr=True)
        _, fqdn, _ = run(
            'kubectl', f'-n {ns} get ingress {ingress_name.decode("utf-8")} -o jsonpath={{.spec.rules[0].host}}', cstdout=True)
        fqdn = fqdn.decode('ascii')
    except Exception as _e:
        fqdn = 'unknown.example.com'
    return fqdn

# IF ns is not None, then return it, otherwise lookup the current namespace context
def get_namespace(ns=None):
    """Get the default namespace from the active kubectl context"""
    if ns != None:
        return ns
    get_context() # Ensure k8s context is set/exists
    _, ctx_namespace, _ = run('kubectl', 'config view --minify --output=jsonpath={..namespace}', cstdout=True)
    return ctx_namespace.decode('ascii') if ctx_namespace else 'default'

def get_context():
    """Get the active kubectl context name"""
    try:
        _, ctx, _ = run('kubectl', 'config view --minify --output=jsonpath={..current-context}', cstdout=True)
    except Exception as _e:
        error('Could not determine current k8s context. Check your kubeconfig file and try again.')
        sys.exit(1)
    return ctx.decode('ascii') if ctx else 'default'

# Lookup the value of a configmap key
def get_configmap_value(ns, configmap, key):
    """
    Get configmap contents.
    ns: target namespace.
    configmap: name of the configmap.
    key: name of the key in the given configmap.
    return value: contents of the configmap key.
    """
    _, value, _ = run('kubectl',
                     f'-n {ns} get configmap {configmap} -o jsonpath={{.data.{key}}}', cstdout=True)
    return value.decode('utf-8')

# Lookup the value of a secret
def get_secret_value(ns, secret, key):
    """
    Get secret contents.
    ns: target namespace.
    secret: name of the secret.
    key: name of the key in the given secret.
    return value: b64 decoded contents of the secret key.
    """
    _, value, _ = run('kubectl',
                     f'-n {ns} get secret {secret} -o jsonpath={{.data.{key}}}', cstdout=True)
    return base64.b64decode(value).decode('utf-8')

# Clean up amster resources.
def clean_amster_job(ns):
    message(f'Cleaning up amster components.')
    run('kubectl', f'-n {ns} delete --ignore-not-found=true job amster')
    run('kubectl', f'-n {ns} delete --ignore-not-found=true cm amster-files')
    run('kubectl', f'-n {ns} delete --ignore-not-found=true cm amster-export-type')
    if os.path.exists('amster-import.tar.gz'):
        os.remove('amster-import.tar.gz')
    if os.path.exists('amster-scripts.tar.gz'):
        os.remove('amster-scripts.tar.gz')
    return

def replace_or_append_str(array, search_str, data):
    """
    Loop through array looking for search_str, and set the idx to data.
    """

    found = False
    for idx, item in enumerate(array):
        if search_str in item:
            found = True
            array[idx] = data
        elif data in item:
            found = True
    if not found:
        array.append(data)

    return array

def replace_or_append_dict(array, search_key, search_str, target_key, replace_data, append_data=None):
    """
    Loop through array of dicts looking for item[search_key] == search_str, and set the target_key to data.
    """

    if not append_data:
        append_data = replace_data

    found = False
    for idx, item in enumerate(array):
        if search_str in item[search_key]:
            found = True
            array[idx][target_key] = replace_data
    if not found:
        array.append(append_data)

    return array

def process_overrides(root_path, helm, kustomize, build, no_helm, no_kustomize, releases_src, pull_policy, source, ssl_secretname, debug=False):
    """
    Process common paths from arguments
    """

    forgeops_root = root_path
    if os.getenv('FORGEOPS_ROOT'):
        forgeops_root = Path(os.getenv('FORGEOPS_ROOT'))

    helm_path = 'helm'
    if helm is not None:
        helm_path = helm
    elif os.getenv('HELM_PATH'):
        helm_path = os.getenv('HELM_PATH')
    if Path(helm_path).is_absolute():
        helm_path = Path(helm_path)
    else:
        helm_path = forgeops_root / helm_path

    build_path = 'docker'
    if build is not None:
        build_path = build
    elif os.getenv('BUILD_PATH'):
        build_path = os.getenv('BUILD_PATH')
    if Path(build_path).is_absolute():
        build_path = Path(build_path)
    else:
        build_path = forgeops_root / build_path

    kustomize_path = 'kustomize'
    if kustomize is not None:
        kustomize_path = kustomize
    elif os.getenv('KUSTOMIZE_PATH'):
        kustomize_path = os.getenv('KUSTOMIZE_PATH')
    if Path(kustomize_path).is_absolute():
        kustomize_path = Path(kustomize_path)
    else:
        kustomize_path = forgeops_root / kustomize_path

    overlay_root = kustomize_path / 'overlay'

    source_overlay = 'default'
    if source:
        source_overlay = source
    elif os.getenv('SOURCE'):
        source_overlay = os.getenv('SOURCE')

    ssl_secret = None
    if ssl_secretname:
        ssl_secret = ssl_secretname
    elif os.getenv('SSL_SECRETNAME'):
        ssl_secret = os.getenv('SSL_SECRETNAME')

    do_helm = True
    if no_helm or os.getenv('NO_HELM') == 'true':
        do_helm = False
    do_kustomize = True
    if no_kustomize or os.getenv('NO_KUSTOMIZE') == 'true':
        do_kustomize = False

    pull_policy_real = None
    if pull_policy:
        pull_policy_real = pull_policy
    elif os.getenv('PULL_POLICY'):
        pull_policy_real = os.getenv('PULL_POLICY')

    r_src = RELEASES_SRC_DEF
    if releases_src:
        r_src = releases_src
    elif os.getenv('RELEASES_SRC'):
        r_src = os.getenv('RELEASES_SRC')
    if not r_src.startswith('http'):
        if Path(r_src).is_absolute():
            r_src = Path(r_src)
        else:
            r_src = root_path / r_src

    if debug:
        print(f'helm_path = {helm_path}')
        print(f'kustomize_path = {kustomize_path}')
        print(f'build_path = {build_path}')
        print(f'overlay_root = {overlay_root}')
        print(f'do_helm = {do_helm}')
        print(f'do_kustomize = {do_kustomize}')
        print(f'releases_src = {releases_src}')
        print(f'forgeops_root = {forgeops_root}')
        print(f'pull_policy = {pull_policy_real}')
        print(f'source_overlay = {source_overlay}')
        print(f'ssl_secretname = {ssl_secretname}')

    return {
        'helm_path': helm_path,
        'kustomize_path': kustomize_path,
        'build_path': build_path,
        'overlay_root': overlay_root,
        'do_helm': do_helm,
        'do_kustomize': do_kustomize,
        'releases_src': r_src,
        'forgeops_root': forgeops_root,
        'pull_policy': pull_policy_real,
        'source_overlay': source_overlay,
        'ssl_secretname': ssl_secret
    }

def key_exists(data, key_str, separator='.'):
    """
    Check to see if a nested key exists.
    ex:
    if key_exists(my_dict, 'platform.ingress.hosts'):
    """

    if type(data) != dict:
        raise Exception("key_exists(): Must provide a dict to look in")
    if type(key_str) != str:
        raise Exception("key_exists(): Must provide a str (key.subkey[.subkey]...) to look for")
    result = True
    k = key_str
    key_str_new = None
    if separator in key_str:
        k, key_str_new = key_str.split(separator, 1)
        if k in data:
            result = key_exists(data[k], key_str_new, separator)
        else:
            result = False
    else:
        if k not in data:
            result = False
    return result

def check_path(path, name, path_type, fail_on_err=False):
    """
    Check to see if path exists and is of a given type.
    path: path to check
    name: friendly name to use when printing the error
    path_type: type of path to check for (dir, file)
    """

    exists = False
    if path_type == 'dir':
        if Path(path).is_dir():
            exists = True
    elif path_type == 'file':
        if Path(path).is_file():
            exists = True

    if fail_on_err and not exists:
        exit_msg(f"{name} ({path}) isn't a {path_type} or doesn't exist")

    return exists

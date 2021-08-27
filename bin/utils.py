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
import pkg_resources
from pathlib import Path

CYAN = '\033[1;96m'
PURPLE = '\033[1;95m'
RED = '\033[1;91m'
ENDC = '\033[0m'
MSG_FMT = '[%(levelname)s] %(message)s'

_IGNORE_FILES = ('.DS_Store',)

log_name = 'foregops'

ALLOWED_COMMONS_CHARS = re.compile(r'[^A-Za-z0-9\s\..]+')

DOCKER_REGEX_NAME = {
    'am': '.*am',
    'amster': '.*amster.*',
    'idm': '.*idm',
    'ds-idrepo': '.*ds-idrepo.*',
    'ds-cts': '.*ds-cts.*',
    'ig': '.*ig.*'
}

REQ_VERSIONS ={
    'ds-operator': {
        'MIN': 'v0.1.0',
        'MAX': 'v100.0.0',
    },
    'secret-agent': {
        'MIN': 'v1.1.1',
        'MAX': 'v100.0.0',
    },
    'minikube': {
        'MIN': 'v1.22.0',
        'MAX': 'v100.0.0',
    },
    'kubectl': {
        'MIN': 'v1.20.0',
        'MAX': 'v100.0.0',
    },
    'kustomize': {
        'MIN': 'v4.2.0',
        'MAX': 'v100.0.0',
    },
    'skaffold':{
        'MIN': 'v1.20.0',
        'MAX': 'v100.0.0',        
    }
}

def inject_kustomize_amster(kustomize_pkg_path): return _inject_kustomize_amster(kustomize_pkg_path)

size_paths = {
    'mini': 'overlay/mini',
    'small': 'overlay/small',
    'medium': 'overlay/medium',
    'large': 'overlay/large',
    'cdk': 'base'
}

bundles = {
    'base': ['dev/kustomizeConfig', 'base/secrets', 'base/ingress', 'dev/scripts'],
	'base-cdm': ['base/kustomizeConfig', 'base/ingress', 'dev/scripts'],
    'ds': ['base/ds-idrepo'],
    'ds-cdm': ['base/ds-idrepo', 'base/ds-cts'],
    'ds-old': ['base/ds/idrepo', 'base/ds/cts'],
    'apps': ['base/am-cdk', 'base/idm-cdk', 'base/rcs-agent', inject_kustomize_amster],
    'ui': ['base/admin-ui', 'base/end-user-ui', 'base/login-ui'],
    'am': ['base/am-cdk'],
    'idm': ['base/idm-cdk'],
    'amster': [inject_kustomize_amster]
}

patcheable_components ={
    'base/am-cdk': 'am.yaml',
    'base/idm-cdk': 'idm.yaml',
    'base/kustomizeConfig': 'base.yaml',
    'base/ds/idrepo': 'ds-idrepo-old.yaml',
    'base/ds/cts': 'ds-cts-old.yaml',
    'base/ds-idrepo': 'ds-idrepo.yaml',
    'base/ds-cts': 'ds-cts.yaml',
    'base/ig': 'ig.yaml',
}

SCRIPT = pathlib.Path(__file__)
SCRIPT_DIR = SCRIPT.parent.resolve()
REPO_BASE_PATH = SCRIPT_DIR.joinpath('../').resolve()
DOCKER_BASE_PATH = REPO_BASE_PATH.joinpath('docker').resolve()
KUSTOMIZE_BASE_PATH = REPO_BASE_PATH.joinpath('kustomize').resolve()


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


class ColorFormatter(logging.Formatter):
    """Logging color"""
    TTY_FORMATS = {
        logging.DEBUG: f'{CYAN}{MSG_FMT}{ENDC}',
        logging.INFO: f'{CYAN}{MSG_FMT}{ENDC}',
        logging.WARNING: f'{PURPLE}{MSG_FMT}{ENDC}',
        logging.ERROR: f'{RED}{MSG_FMT}{ENDC}',
        logging.CRITICAL: f'{RED}{MSG_FMT}{ENDC}',
    }
    NON_TTY_FORMATS = {
        logging.DEBUG: f'{MSG_FMT}',
        logging.INFO: f'{MSG_FMT}',
        logging.WARNING: f'{MSG_FMT}',
        logging.ERROR: f'{MSG_FMT}',
        logging.CRITICAL: f'{MSG_FMT}',


    }
    def format(self, record):
        if not sys.stdout.isatty():
            log_fmt = self.NON_TTY_FORMATS.get(record.levelno)
        else:
            log_fmt = self.TTY_FORMATS.get(record.levelno)
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
    run('kubectl',
        f'-n {ns} rollout status --watch statefulset {directoryservices_name} --timeout=300s')
    _runwithtimeout(_waitfords, [ns, directoryservices_name], 120)

def generate_package(component, size, ns, fqdn, ctx, custom_path=None):
    """Generate Kustomize package for component or bundle"""
    # Clean out the temp kustomize files
    kustomize_dir = os.path.join(sys.path[0], '../kustomize')
    src_profile_dir = os.path.join(kustomize_dir, size_paths[size])
    image_defaulter = os.path.join(kustomize_dir, 'dev', 'image-defaulter')
    profile_dir = custom_path or os.path.join(kustomize_dir, 'deploy', component)
    shutil.rmtree(profile_dir, ignore_errors=True)
    Path(profile_dir).mkdir(parents=True, exist_ok=True)
    run('kustomize', f'create', cwd=profile_dir)
    run('kustomize', f'edit add component {os.path.relpath(image_defaulter, profile_dir)}', 
              cwd=profile_dir)
    components_to_install = bundles.get(component, [f'base/{component}'])
    # Temporarily add the wanted kustomize files
    for c in components_to_install:
        if callable(c):
            c(profile_dir)
        else:
            run('kustomize', f'edit add resource ../../../kustomize/{c}', cwd=profile_dir)
        if c in patcheable_components and size != 'cdk':
            p = patcheable_components[c]
            shutil.copy(os.path.join(src_profile_dir, p), profile_dir)
            run('kustomize', f'edit add patch --path {p}', cwd=profile_dir)

    fqdnpatchjson = [{"op": "replace", "path": "data/data/FQDN", "value": fqdn}]
    # run('kustomize', f'edit set namespace {ns}', cwd=profile_dir)
    if component in ['base', 'base-cdm']:
        run('kustomize', f'edit add patch --name platform-config --kind ConfigMap --version v1 --patch \'{json.dumps(fqdnpatchjson)}\'',
            cwd=profile_dir) 
    _, contents, _ = run('kustomize', f'build {profile_dir}', cstdout=True)
    contents = contents.decode('ascii')
    contents = contents.replace('namespace: default', f'namespace: {ns}')
    contents = contents.replace('namespace: prod', f'namespace: {ns}')
    if ctx.lower() == 'minikube':
        contents = contents.replace('imagePullPolicy: Always', 'imagePullPolicy: IfNotPresent')
    return profile_dir, contents

def install_component(component, size, ns, fqdn, ctx, pkg_base_path=None):
    """Generate and deploy component or bundle"""
    pkg_base_path = pkg_base_path or os.path.join(sys.path[0], '..', 'kustomize', 'deploy')
    custom_path = os.path.join(pkg_base_path, component)
    _, contents = generate_package(component, size, ns, fqdn, ctx, custom_path=custom_path)
    run('kubectl', f'-n {ns} apply -f -', stdin=bytes(contents, 'ascii'))

def uninstall_component(component, ns, force):
    """Uninstall a profile"""
    if  component == "all":
        for c in ['ui', 'apps', 'ds', 'base']:
            uninstall_component(c, ns, force)
        return
    try:
        # generate a manifest with the components to be uninstalled in a temp location
        kustomize_dir = os.path.join(sys.path[0], '../kustomize')
        uninstall_dir = os.path.join(kustomize_dir, 'deploy', 'uninstall-temp')
        _, contents = generate_package(component, 'cdk', ns, '.', '', custom_path=uninstall_dir)
        run('kubectl', f'-n {ns} delete --ignore-not-found=true -f -', stdin=bytes(contents, 'ascii'))
        if component == 'base' and force:
            run('kubectl', f'-n {ns} delete all -l app.kubernetes.io/part-of=forgerock')
            run('kubectl', f'-n {ns} delete pvc --all --ignore-not-found=true')
            uninstall_component('secrets', ns, False)
    except Exception as e:
        print(f'Could not delete {component}. Got: {e}')
        sys.exit(1)  # Hide python traceback.
    finally:
        #clean up temp folder
        shutil.rmtree(uninstall_dir, ignore_errors=True)

def _inject_kustomize_amster(kustomize_pkg_path):
    docker_dir = os.path.join(sys.path[0], '../docker')
    amster_cm_name = 'amster-files.yaml'
    amster_cm_path = os.path.join(kustomize_pkg_path, amster_cm_name)
    amster_config_path = os.path.join(docker_dir, 'amster', 'config-profiles', 'cdk')
    amster_scripts_path = os.path.join(docker_dir, 'amster', 'scripts')
    try:
        envVars = os.environ
        envVars['COPYFILE_DISABLE'] = '1'  #skips "._" files in macOS.
        run('tar', f'-czf amster-import.tar.gz -C {amster_config_path} .', cstdout=True, env=envVars)
        run('tar', f'-czf amster-scripts.tar.gz -C {amster_scripts_path} .', cstdout=True, env=envVars)
        _, cm, _ = run('kubectl', f'create cm amster-files --from-file=amster-import.tar.gz --from-file=amster-scripts.tar.gz --dry-run=client -o yaml',
                             cstdout=True)
        with open(amster_cm_path, 'wt') as f:
            f.write(cm.decode('ascii'))
        run('kustomize', f'edit add resource ../../../kustomize/base/amster-upload', cwd=kustomize_pkg_path)
        run('kustomize', f'edit add resource {amster_cm_name}', cwd=kustomize_pkg_path)
    finally:
        if os.path.exists('amster-import.tar.gz'): 
            os.remove('amster-import.tar.gz')
        if os.path.exists('amster-scripts.tar.gz'): 
            os.remove('amster-scripts.tar.gz')

def printsecrets(ns, to_stdout=True):
    """Print relevant platform secrets"""
    try:
        secrets = {
            'am-env-secrets': {
                'AM_PASSWORDS_AMADMIN_CLEAR': None 
            },
            'idm-env-secrets': {
                'OPENIDM_ADMIN_PASSWORD': None
            },
            'rcs-agent-env-secrets':{
                'AGENT_IDM_SECRET': None,
                'AGENT_RCS_SECRET': None,
            },
            'ds-passwords': {
                'dirmanager\\\.pw': None,
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
            print(
                f"{secrets['idm-env-secrets']['OPENIDM_ADMIN_PASSWORD']} (openidm-admin user)")
            print(
                f"{secrets['rcs-agent-env-secrets']['AGENT_IDM_SECRET']} (rcs-agent IDM secret)")
            print(
                f"{secrets['rcs-agent-env-secrets']['AGENT_RCS_SECRET']} (rcs-agent RCS secret)")
            print("{} (uid=admin user)".format(secrets['ds-passwords']['dirmanager\\\.pw']))  # f'strings' do not allow '\'
            print(f"{secrets['ds-env-secrets']['AM_STORES_APPLICATION_PASSWORD']} (App str svc acct (uid=am-config,ou=admins,ou=am-config))")
            print(f"{secrets['ds-env-secrets']['AM_STORES_CTS_PASSWORD']} (CTS svc acct (uid=openam_cts,ou=admins,ou=famrecords,ou=openam-session,ou=tokens))")
            print(f"{secrets['ds-env-secrets']['AM_STORES_USER_PASSWORD']} (ID repo svc acct (uid=am-identity-bind-account,ou=admins,ou=identities))")
        return secrets
    except Exception as _e:
        sys.exit(1)


def printurls(ns, to_stdout=True):
    """Print relevant platform URLs"""
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


def check_component_version(component, version):

    version = pkg_resources.parse_version(version)
    version_max = pkg_resources.parse_version(REQ_VERSIONS[component]['MAX'])
    version_min = pkg_resources.parse_version(REQ_VERSIONS[component]['MIN'])
    if not version_min <= version <= version_max:
        error(f'Unsupported {component} version found: "{version}"')
        message(f'Need {component} versions between {version_min} and {version_max}')
        sys.exit(1)

def check_base_toolset():
    # print('Checking kubectl version')
    _, ver, _ = run('kubectl', 'version --client=true --short', cstdout=True)
    ver = ver.decode('ascii').split(' ')[-1].strip()
    check_component_version('kubectl', ver)
    
    # print('Checking kustomize version')
    _, ver, _ = run('kustomize', 'version --short', cstdout=True)
    ver = ver.decode('ascii').split()[0].split('/')[-1]
    check_component_version('kustomize', ver)

    # print('Checking skaffold version')
    _, ver, _ = run('skaffold', 'version', cstdout=True)
    check_component_version('skaffold', ver.decode('ascii').strip())

def install_dependencies():
    """Check and install dependencies"""
    check_base_toolset()
    print('Checking secret-agent operator and related CRDs:', end=' ')
    try:
        run('kubectl', 'get crd secretagentconfigurations.secret-agent.secrets.forgerock.io',
            cstderr=True, cstdout=True)
    except Exception as _e:
        warning('secret-agent CRD not found. Installing secret-agent.')
        secretagent('apply')
    else:
        message('secret-agent CRD found in cluster.')

    _, img, _= run('kubectl', f'-n secret-agent-system get deployment secret-agent-controller-manager -o jsonpath={{.spec.template.spec.containers[0].image}}',
        cstderr=True, cstdout=True)
    check_component_version('secret-agent', img.decode('ascii').split(':')[1])

    print('Checking ds-operator and related CRDs:', end=' ')
    try:
        run('kubectl', 'get crd directoryservices.directory.forgerock.io',
            cstderr=True, cstdout=True)
    except Exception:
        warning('ds-operator CRD not found. Installing ds-operator.')
        dsoperator('apply')
    else:
        message('ds-operator CRD found in cluster.')

    _, img, _= run('kubectl', f'-n fr-system get deployment ds-operator-ds-operator -o jsonpath={{.spec.template.spec.containers[0].image}}',
        cstderr=True, cstdout=True)
    check_component_version('ds-operator', img.decode('ascii').split(':')[1])
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
    run('skaffold',
        f'build -p {component} --file-output=tag.json {default_repo_cmd} {tag_cmd}', cwd=base_dir, env=envVars)
    with open(os.path.join(base_dir, 'tag.json')) as tag_file:
        tag_data = json.load(tag_file)['builds'][0]["tag"]
    return tag_data


def configure_platform_images(clone_path,
                              ref='',
                              repo='ssh://git@stash.forgerock.org:7999/cloud/platform-images.git'):
    """
    Clone platform images and checkout branch to the given path.
    Raise exception if not succesful
    """
    log = logger()
    path = pathlib.Path(clone_path)

    def grun(*args, **kwargs):
        run('git', '-C', str(path), *args, cstdout=True, cstderr=True)

    git_dir = path.joinpath('.git')
    # handle existing config directory
    if git_dir.is_dir() and ref != '':
        log.info('Found existing files, attempting to not clone')
        try:
            # capture stdout and stderr so git doesn't write to log
            run('git', '-C', str(path), 'checkout',
                ref, cstdout=True, cstderr=True)
            return
        except:
            log.error('Couldn\'t find reference. Getting fresh clone')
            shutil.rmtree(str(path))
    elif git_dir.is_dir():
        log.info('Using existing repo, remove it to get a fresh clone')
        return
    # some path that's not a git repo so don't do anything.
    elif any(path.glob('*')) and not git_dir.is_dir():
        raise Exception('Found existing directory that is not a git repo')
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
        log.error(f'Couldn\'t configure repo running {e.cmd} {e.output}')
        raise e
    except Exception as e:
        log.error(f'Couldn\t configure repo {e}')
        raise e

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

def get_fqdn(ns):
    _, fqdn, _ = run(
        'kubectl', f'-n {ns} get ingress forgerock -o jsonpath={{.spec.rules[0].host}}', cstdout=True)
    return fqdn.decode('ascii')

# IF ns is not None, then return it, otherwise lookup the current namespace context
def get_namespace(ns=None):
    if ns != None:
        return ns
    _, ctx_namespace, _ = run('kubectl', 'config view --minify --output=jsonpath={..namespace}', cstdout=True)
    return ctx_namespace.decode('ascii') if ctx_namespace else 'default'

def get_context():
    _, ctx, _ = run('kubectl', 'config view --minify --output=jsonpath={..current-context}', cstdout=True)
    return ctx.decode('ascii') if ctx else 'default'

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

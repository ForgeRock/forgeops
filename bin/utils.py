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
from pathlib import Path
import sys
file_name = Path(__file__)
current_file_path = file_name.parent.resolve()
root_dir = [parent_path for parent_path in current_file_path.parents if (parent_path / 'README.md').exists()][0]

CYAN = '\033[1;96m'
PURPLE = '\033[1;95m'
BLUE = '\033[1;94m'
RED = '\033[1;91m'
ENDC = '\033[0m'
MSG_FMT = '[%(levelname)s] %(message)s'

_IGNORE_FILES = ('.DS_Store',)

log_name = 'forgeops'

ALLOWED_COMMONS_CHARS = re.compile(r'[^A-Za-z0-9\s\..]+')

DOCKER_REGEX_NAME = {
    'am': 'am',
    'amster': 'amster',
    'idm': 'idm',
    'ds-idrepo-old': 'ds-idrepo-old',
    'ds-cts-old': 'ds-cts-old',
    'ds-idrepo': 'ds-idrepo',
    'ds-cts': 'ds-cts',
    'ds': 'ds',
    'ig': 'ig'
}

REQ_VERSIONS ={
    'ds-operator': {
        'MIN': 'v0.2.9',
        'MAX': 'v100.0.0',
        'DEFAULT': 'v0.2.9',
    },
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

def inject_kustomize_amster(kustomize_profile_path, config_profile): return _inject_kustomize_amster(kustomize_profile_path, config_profile)

size_paths = {
    'mini': 'overlay/mini',
    'small': 'overlay/small',
    'medium': 'overlay/medium',
    'large': 'overlay/large',
    'cdk': 'base'
}

bundles = {
	'base': ['base/kustomizeConfig', 'base/ingress'],
    'ds-operator': ['base/ds-idrepo', 'base/ds-cts'],
    'ds': ['base/ds/idrepo', 'base/ds/cts', 'base/ldif-importer'],
    'ds-idrepo': ['base/ds/idrepo', 'base/ldif-importer'],
    'ds-cts': ['base/ds/cts', 'base/ldif-importer'],
    'ds-idrepo-op': ['base/ds-idrepo'],
    'ds-cts-op': ['base/ds-cts'],
    'ds-old': ['base/ds-legacy/idrepo', 'base/ds-legacy/cts', 'base/ldif-importer'],
    'apps': ['base/am', 'base/idm', inject_kustomize_amster],
    'ui': ['base/admin-ui', 'base/end-user-ui', 'base/login-ui'],
    'am': ['base/am'],
    'idm': ['base/idm'],
    'amster': [inject_kustomize_amster]
}

patcheable_components ={
    'base/am': 'am.yaml',
    'base/idm': 'idm.yaml',
    'base/kustomizeConfig': 'base.yaml',
    'base/ds/idrepo': 'ds-idrepo.yaml',
    'base/ds/cts': 'ds-cts.yaml',
    'base/ds-legacy/idrepo': 'ds-idrepo-old.yaml',
    'base/ds-legacy/cts': 'ds-cts-old.yaml',
    'base/ds-idrepo': 'ds-idrepo-op.yaml',
    'base/ds-cts': 'ds-cts-op.yaml',
    'base/ig': 'ig.yaml',
    'base/ingress': 'ingress.yaml',
    'base/secrets': 'secret_agent_config.yaml'
}

SCRIPT = pathlib.Path(__file__)
SCRIPT_DIR = SCRIPT.parent.resolve()
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


def _waitfords(ns, ds_name, legacy, operator):
    """
    Wait for DS deployment to become healthy. This is a blocking call with no timeout.
    ns: target namespace.
    ds_name: name of the DS deployment to evaluate.
    """
    print(f'Waiting for Service Account Password Update: ', end='')
    sys.stdout.flush()
    if operator:
        _, replicas, _ = run('kubectl', f'-n {ns} get directoryservices.directory.forgerock.io {ds_name} -o jsonpath={{.spec.replicas}}',
                    cstderr=True, cstdout=True)
    else:
        _, replicas, _ = run('kubectl', f'-n {ns} get statefulset {ds_name} -o jsonpath={{.spec.replicas}}',
                    cstderr=True, cstdout=True)
    if replicas.decode('utf-8') == '0':
        print('skipped')
        return
    while True:
        try:
            if operator:
                _, valuestr, _ = run('kubectl', f'-n {ns} get directoryservices.directory.forgerock.io {ds_name} -o jsonpath={{.metadata.annotations.password-updated-status}}',
                                 cstderr=True, cstdout=True)
            else:
                _, valuestr, _ = run('kubectl', f'wait -n {ns} job/ldif-importer --for=condition=complete --timeout=60s',
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

def waitforsecrets(ns, timeout=60):
    """
    Wait for the platform secrets to exist in the Kubernetes api. Times out after 60 secs.
    ns: target namespace.
    """
    secrets = ['am-env-secrets', 'idm-env-secrets',
               'ds-passwords', 'ds-env-secrets']
    message('\nWaiting for K8s secrets.')
    for secret in secrets:
        _runwithtimeout(_waitforresource, [ns, 'secret', secret], timeout)


def wait_for_ds(ns, directoryservices_name, legacy, operator, timeout_secs=600):
    """
    Wait for DS pods to be ready after ds-operator deployment.
    ns: target namespace.
    directoryservices_name: name of the DS deployment to evaluate.
    timeout_secs: timeout in secs.
    """
    _runwithtimeout(_waitforresource, [ns, 'statefulset', directoryservices_name], 30)
    run('kubectl',
        f'-n {ns} rollout status --watch statefulset {directoryservices_name} --timeout={timeout_secs}s')
    _runwithtimeout(_waitfords, [ns, directoryservices_name, legacy, operator], timeout_secs)

def wait_for_am(ns, timeout_secs=600):
    """
    Wait for AM pods to be ready after deployment.
    ns: Target namespace.
    timeout_secs: timeout in secs.
    """
    _runwithtimeout(_waitforresource, [ns, 'deployment', 'am'], 30)
    return run('kubectl', f'-n {ns} wait --for=condition=Available deployment -l app.kubernetes.io/name=am --timeout={timeout_secs}s')

def wait_for_amster(ns, duration, timeout_secs=600):
    """
    Wait for successful amster job run.
    ns: target namespace.
    timeout_secs: timeout in secs.
    """
    _runwithtimeout(_waitforresource, [ns, 'job', 'amster'], 30)

    condition = 'ready' if duration > '10' else 'complete'

    return run('kubectl', f'-n {ns} wait --for=condition={condition} job/amster --timeout={timeout_secs}s')

def wait_for_idm(ns, timeout_secs=600):
    """
    Wait for IDM pods to be ready after deployment.
    ns: target namespace.
    timeout_secs: timeout in secs.
    """
    _runwithtimeout(_waitforresource, [ns, 'deployment', 'idm'], 30)
    return run('kubectl', f'-n {ns} wait --for=condition=Ready pod -l app.kubernetes.io/name=idm --timeout={timeout_secs}s')

def generate_package(component, size, ns, fqdn, ingress_class, ctx, legacy, config_profile, operator, custom_path=None, src_profile_dir=None, deploy_path=None):
    """
    Generate Kustomize package and manifests for given component or bundle.
    component: name of the component or bundle to generate. e.a. base, apps, am, idm, ui, admin-ui, etc.
    size: size of the component to generate. e.a. cdk, mini, small, medium, large.
    ns: target namespace.
    fqdn: set the FQDN used in the generated package.
    ctx: specify current kubernetes context. Some environments require special steps. e.a. minikube.
    custom_path: path to store generated files. Defaults to FORGEOPS_REPO/kustomize/deploy/COMPONENT.
    src_profile_dir: path to the overlay where kustomize patches are located. Defaults to kustomize/overlay/SIZE or kustomize/base/ if CDK.
    deploy_env: path to root of generated kustomize deployment manifests. Defaults to kustomize/deploy-[--deploy-path value if requested] or kustomize/deploy if --deploy-path parameter not requested.
    return profile_dir: path to the generated package.
    return contents: generated kubernetes manifest. This is equivalent to `kustomize build profile_dir`.
    """
    # Clean out the temp kustomize files
    kustomize_dir = os.path.join(root_dir, 'kustomize')
    src_profile_dir = src_profile_dir or os.path.join(kustomize_dir, size_paths[size])
    image_defaulter = os.path.join(deploy_path, 'image-defaulter') if deploy_path else os.path.join(kustomize_dir, 'deploy', 'image-defaulter')
    profile_dir = custom_path or os.path.join(deploy_path, component)
    shutil.rmtree(profile_dir, ignore_errors=True)
    Path(profile_dir).mkdir(parents=True, exist_ok=True)
    run('kustomize', f'create', cwd=profile_dir)
    run('kustomize', f'edit add component {os.path.relpath(image_defaulter, profile_dir)}',
              cwd=profile_dir)

    # Set component to DS Operator if operator argument is true
    if operator:
        log.debug('ds-operator requested.')
        if component == 'ds':
            component = 'ds-operator'
        if component == 'ds-idrepo':
            component = 'ds-idrepo-op'
        if component == 'ds-cts':
            component = 'ds-cts-op'

    log.debug('component = ' + component)
    components_to_install = bundles.get(component, [f'base/{component}'])

    # Check components when installing ds-idrepo or ds-cts to ensure the correct components are installed
    if operator and (component == "ds-idrepo" or component == "ds-cts"):
        components_to_install = bundles.get(component, [f'base/{component}'])
    elif not operator and (component == "ds-idrepo" or component == "ds-cts"):
        components_to_install = bundles.get(component, [f'base/ds/{component}'])
    else:
        components_to_install = bundles.get(component, [f'base/{component}'])

    # Temporarily add the wanted kustomize files
    for c in components_to_install:
        if callable(c):
            c(profile_dir, config_profile)
        else:
            run('kustomize', f'edit add resource ../../../kustomize/{c}', cwd=profile_dir)
        if c in patcheable_components and size != 'cdk':
            p = patcheable_components[c]
            if os.path.exists(os.path.join(src_profile_dir, p)):
                shutil.copy(os.path.join(src_profile_dir, p), profile_dir)
                run('kustomize', f'edit add patch --path {p}', cwd=profile_dir)

    fqdnpatchjson = [{"op": "replace", "path": "data/data/FQDN", "value": fqdn}]
    if operator:
        dsoperatorpatchjson = [{"op": "add", "path": "data/data/DS_OPERATOR_ENABLED", "value": "true"}]
    ingressclasspatchjson = [{"op": "replace", "path": "/spec/ingressClassName", "value": ingress_class}]
    if component in ['base']:
        run('kustomize', f'edit add patch --name platform-config --kind ConfigMap --version v1 --patch \'{json.dumps(fqdnpatchjson)}\'',
            cwd=profile_dir)
        if operator:
            run('kustomize', f'edit add patch --name platform-config --kind ConfigMap --version v1 --patch \'{json.dumps(dsoperatorpatchjson)}\'',
                cwd=profile_dir)
        run('kustomize', f'edit add patch --name forgerock --kind Ingress --version v1 --patch \'{json.dumps(ingressclasspatchjson)}\'',
            cwd=profile_dir)
        run('kustomize', f'edit add patch --name ig --kind Ingress --version v1 --patch \'{json.dumps(ingressclasspatchjson)}\'',
            cwd=profile_dir)
        # run('kustomize', f'edit add patch --name icf-ingress --kind Ingress --version v1 --patch \'{json.dumps(ingressclasspatchjson)}\'',
        #     cwd=profile_dir)
    _, contents, _ = run('kustomize', f'build {profile_dir}', cstdout=True)
    contents = contents.decode('ascii')
    contents = contents.replace('namespace: default', f'namespace: {ns}')
    contents = contents.replace('namespace: prod', f'namespace: {ns}')
    if ctx.lower() == 'minikube':
        contents = contents.replace('imagePullPolicy: Always', 'imagePullPolicy: IfNotPresent')
        contents = contents.replace('storageClassName: fast', 'storageClassName: standard')
    return profile_dir, contents

def install_component(component, size, ns, fqdn, ingress_class, ctx, duration, legacy, config_profile, operator, deploy_path=None, src_profile_dir=None):
    """
    Generate and deploy the given component or bundle.
    component: name of the component or bundle to generate and install. e.a. base, apps, am, idm, ui, admin-ui, etc.
    size: size of the component to generate and install. e.a. cdk, mini, small, medium, large.
    ns: target namespace.
    fqdn: set the FQDN used in the deployment.
    ctx: specify current kubernetes context. Some environments require special steps. e.a. minikube.
    deploy_path: base path to store generated files. Defaults to FORGEOPS_REPO/kustomize/deploy.
    src_profile_dir: path to the overlay where kustomize patches are located. Defaults to kustomize/overlay/SIZE or kustomize/base/ if CDK.
    """
    deploy_path = deploy_path or os.path.join(root_dir, 'kustomize', 'deploy')
    custom_path = os.path.join(deploy_path, component)
    _, contents = generate_package(component, size, ns, fqdn, ingress_class, ctx, legacy, config_profile, operator, custom_path=custom_path, src_profile_dir=src_profile_dir, deploy_path=deploy_path)

    # Remove amster components
    if component == "amster":
        clean_amster_job(ns, False)

    # Create amster-retain configmap which defines the
    if component == 'amster':
        run('kubectl', f'-n {ns} create cm amster-retain --from-literal=DURATION={duration}')

    run('kubectl', f'-n {ns} apply -f -', stdin=bytes(contents, 'ascii'))

def uninstall_component(component, ns, force, ingress_class, legacy, config_profile, operator):
    """
    Uninstall a component.
    component: name of the component or bundle to uninstall. e.a. base, apps, am, idm, ui, admin-ui, etc.
    ns: target namespace.
    force: set to True to delete all forgeops resources including secrets and PVCs.
    """
    # Supports deleting of DS Operator custom resources when upgrading from 7.3 to 7.4
    if component in ['ds','ds-idrepo','ds-cts']:
        try:
            # Check if the directoryservice CRD is installed. If not then skip the delete.
            run('kubectl', 'get crd directoryservices.directory.forgerock.io', cstderr=True, cstdout=True)
        except:
            pass
        else:
            if component in ['ds','ds-idrepo']:
                run('kubectl', f'-n {ns} delete --ignore-not-found=true directoryservice ds-idrepo')
            if component in ['ds','ds-cts']:
                run('kubectl', f'-n {ns} delete --ignore-not-found=true directoryservice ds-cts')

    if component == "all":
        for c in ['ui', 'apps', 'ds', 'base']:
            uninstall_component(c, ns, force, ingress_class, legacy, operator)
        return
    try:
        # generate a manifest with the components to be uninstalled in a temp location
        kustomize_dir = os.path.join(root_dir, 'kustomize')
        uninstall_dir = os.path.join(kustomize_dir, 'deploy', 'uninstall-temp')
        _, contents = generate_package(component, 'cdk', ns, '.', ingress_class, '', legacy, config_profile, operator, custom_path=uninstall_dir)
        run('kubectl', f'-n {ns} delete --ignore-not-found=true -f -', stdin=bytes(contents, 'ascii'))
        if component == "amster":
            clean_amster_job(ns, False)
            run('kubectl', f'-n {ns} delete cm amster-retain')
    except Exception as e:
        print(f'Could not delete {component}. Got: {e}')
        sys.exit(1)  # Hide python traceback.
    finally:
        #clean up temp folder
        shutil.rmtree(uninstall_dir, ignore_errors=True)

def _inject_kustomize_amster(kustomize_profile_path, config_profile):
    docker_dir = os.path.join(root_dir, 'docker')
    amster_cm_name = 'amster-files.yaml'
    amster_cm_path = os.path.join(kustomize_profile_path, amster_cm_name)
    amster_config_path = os.path.join(docker_dir, 'amster', 'config-profiles', config_profile)
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
        run('kustomize', f'edit add resource ../../../kustomize/overlay/amster-upload', cwd=kustomize_profile_path)
        run('kustomize', f'edit add resource {amster_cm_name}', cwd=kustomize_profile_path)
    finally:
        if os.path.exists('amster-import.tar.gz'):
            os.remove('amster-import.tar.gz')
        if os.path.exists('amster-scripts.tar.gz'):
            os.remove('amster-scripts.tar.gz')

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
            print("{} (uid=admin user)".format(secrets['ds-passwords']['dirmanager\\\.pw']))  # f'strings' do not allow '\'
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

def is_legacy_install(ns):
    _, _, out = run('kubectl', f'-n {ns} get sts -l app.kubernetes.io/managed-by=ds-operator', cstderr=True, cstdout=True)
    if "No resources found" in out.decode('utf-8'):
        return False
    else:
        return True

def dsoperator(k8s_op, tag='latest'):
    """Check if ds-operator is present in the cluster. If not, installs it."""
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


def _install_certmanager_issuer():
    """Install certmanager self-signed issuer. This works as a placeholder issuer."""
    addons_dir = os.path.join(root_dir, 'cluster', 'addons', 'certmanager')
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



def build_docker_image(component, context, dockerfile, push_to, tag, container_engine,
                       config_profile=None):
    """
    Build custom docker images.
    component: name of the component to build the image for. e.a. am, idm, etc.
    push_to: set the docker registry name to push to. e.a. us-docker.pkg.dev/forgeops-public/images.
    tag: set the image tag.
    config_profile: set the CONFIG_PROFILE build envVar. This envVar is referenced by the Dockerfile of forgeops containers.
    return tag_data: the tag of the built image.
    """
    # Clean out the temp kustomize files
    if config_profile:
        build_args = f'--build-arg CONFIG_PROFILE={config_profile}'
    else:
        build_args = ''
    if push_to.lower() != 'none':
        image = f'{push_to}/{component}'
    else:
        image = f'{component}'
    if tag is not None:
        if push_to.lower() != 'none':
            image = f'{push_to}/{component}:{tag}'
        else:
            image = f'{component}:{tag}'
    run(f'{container_engine}',
        f'build {build_args} -t {image} -f {dockerfile} {context}', cwd=root_dir)
    if push_to.lower() != 'none':
        run(f'{container_engine}', f'push {image}', cwd=root_dir)
    return image


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
    _, ingress_name, _ = run(
        'kubectl', f'-n {ns} get ingress -o jsonpath={{.items[0].metadata.name}}', cstdout=True)
    _, fqdn, _ = run(
        'kubectl', f'-n {ns} get ingress {ingress_name.decode("utf-8")} -o jsonpath={{.spec.rules[0].host}}', cstdout=True)
    return fqdn.decode('ascii')

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
def clean_amster_job(ns, retain):
    if not retain:
        message(f'Cleaning up amster components.')
        run('kubectl', f'-n {ns} delete --ignore-not-found=true job amster')
        run('kubectl', f'-n {ns} delete --ignore-not-found=true cm amster-files')
        run('kubectl', f'-n {ns} delete --ignore-not-found=true cm amster-export-type')
        run('kubectl', f'-n {ns} delete --ignore-not-found=true cm amster-retain')
    if os.path.exists('amster-import.tar.gz'):
        os.remove('amster-import.tar.gz')
    if os.path.exists('amster-scripts.tar.gz'):
        os.remove('amster-scripts.tar.gz')
    return

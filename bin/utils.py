"""This is a shared lib used by other /bin python scripts"""

import subprocess
import sys
import time
from threading import Thread

CYAN = '\033[1;96m'
PURPLE = '\033[1;95m'
RED = '\033[1;91m'
ENDC = '\033[0m'

def message(s):
    """Print info message"""
    print(f"{CYAN}{s}{ENDC}")
def error(s):
    """Print error message"""
    print(f"{RED}{s}{ENDC}")
def warning(s):
    """Print warning message"""
    print(f"{PURPLE}{s}{ENDC}")

def run(cmd, *cmdArgs, stdin=None, cstdout=False, cstderr=False, cwd=None):
    """rC runs a given command. Raises error if command returns non-zero code"""
    runcmd = f'{cmd} {" ".join(cmdArgs)}'
    stde_pipe = subprocess.PIPE if cstderr else None
    stdo_pipe = subprocess.PIPE if cstdout else None
    _r = subprocess.run(runcmd.split(), stdout=stdo_pipe, stderr=stde_pipe,
                        check=True, input=stdin, cwd=cwd)
    return _r.returncode == 0, _r.stdout, _r.stderr

def _waitforsecret(ns, secret_name):
    print(f'Waiting for secret: {secret_name} .', end='')
    sys.stdout.flush()
    while True:
        try:
            run('kubectl', f'-n {ns} get secret {secret_name}', cstderr=True, cstdout=True)
            print('done')
            break
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
        print(f"{getsec(ns, 'am-env-secrets', 'AM_PASSWORDS_AMADMIN_CLEAR')} (amadmin user)")
        print(f"{getsec(ns, 'idm-env-secrets', 'OPENIDM_ADMIN_PASSWORD')} (openidm-admin user)")
        print(f"{getsec(ns, 'rcs-agent-env-secrets', 'AGENT_IDM_SECRET')} (rcs-agent IDM secret)")
        print(f"{getsec(ns, 'rcs-agent-env-secrets', 'AGENT_RCS_SECRET')} (rcs-agent RCS secret)")
        print("{} (uid=admin user)".format(getsec(ns, 'ds-passwords', 'dirmanager\\.pw'))) #f'strings' do not allow '\'
        print(f"{getsec(ns, 'ds-env-secrets', 'AM_STORES_APPLICATION_PASSWORD')} (App str svc acct (uid=am-config,ou=admins,ou=am-config))")
        print(f"{getsec(ns, 'ds-env-secrets', 'AM_STORES_CTS_PASSWORD')} (CTS svc acct (uid=openam_cts,ou=admins,ou=famrecords,ou=openam-session,ou=tokens))")
        print(f"{getsec(ns, 'ds-env-secrets', 'AM_STORES_USER_PASSWORD')} (ID repo svc acct (uid=am-identity-bind-account,ou=admins,ou=identities))")
    except Exception as _e:
        sys.exit(1)

def printurls(ns):
    """Print relevant platform URLs"""
    message('\nRelevant URLs:')
    _, fqdn, _ = run('kubectl', f'-n {ns} get ingress forgerock -o jsonpath={{.spec.rules[0].host}}', cstdout=True)
    fqdn = fqdn.decode('ascii')
    warning(f'https://{fqdn}/platform')
    warning(f'https://{fqdn}/admin')
    warning(f'https://{fqdn}/am')
    warning(f'https://{fqdn}/enduser')

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

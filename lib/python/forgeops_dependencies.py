import json
import re
import sys
import os
import site
from pathlib import Path
try:
    import pkg_resources
except:
    print('[error] You must install setuptool pyhon module. '
          'You may want to try something like : pip3 install setuptools')
    sys.exit(1)

file_name = Path(__file__)
current_file_path = file_name.parent.resolve()
root_dir = [parent_path for parent_path in current_file_path.parents if (parent_path / 'README.md').exists()][0]
bin_dir = os.path.join(root_dir, 'bin')
dependencies_dir = os.path.join(root_dir, 'lib', 'dependencies')
# Insert lib folders to python path
sys.path.insert(0, str(root_dir))
sys.path.insert(1, str(bin_dir) + site.USER_SITE.replace(site.USER_BASE, ''))
sys.path.insert(2, str(dependencies_dir) + site.USER_SITE.replace(site.USER_BASE, ''))

from bin.utils import REQ_VERSIONS, error, message, run, warning, certmanager, secretagent, dsoperator


def check_component_version(component, version):
    """
    Check if the given component is within the accepted version range.
    component: name of the component to verify. e.a. kustomize, etc.
    version: version string to verify. If the version is out of range, an error is raised program terminates.
    """
    version = pkg_resources.parse_version(version)
    version_max = pkg_resources.parse_version(REQ_VERSIONS[component]['MAX'])
    version_min = pkg_resources.parse_version(REQ_VERSIONS[component]['MIN'])
    if not version_min <= version <= version_max:
        error(f'Unsupported {component} version found: "{version}".')
        message(f'Need {component} versions between {version_min} and {version_max}.')
        sys.exit(1)


def check_base_toolset():
    """
    Verify if the components/tools required are present and if they are the correct version.
    """
    # print('Checking kubectl version')
    _, output, _ = run('kubectl', 'version --client=true -o json', cstdout=True)
    output = json.loads(output.decode('utf-8'))['clientVersion']['gitVersion']
    check_component_version('kubectl', re.split('-|_|\+', output)[0])

    # print('Attempting to check Kubernetes server version')
    try:
        _, output, _ = run('kubectl', 'version -o json', cstdout=True, cstderr=True)
        output = json.loads(output.decode('utf-8'))['serverVersion']['gitVersion']
    except:
        message('Could not verify Kubernetes server version. Continuing for now.')
    check_component_version('kubernetes', re.split('-|_|\+', output)[0])

    # print('Checking kustomize version')
    _, ver, _ = run('kustomize', 'version', cstdout=True)
    ver = ver.decode('ascii')
    check_component_version('kustomize', ver)


def forgeops_dependencies(legacy, operator):
    """
    Check for and install dependencies in the kubernetes cluster if they are not found.
    If dependencies are found in K8s, this function does not modify or reinstall the components.
    """
    check_base_toolset()

    print('Checking cert-manager and related CRDs:', end=' ')
    try:
        run('kubectl', 'get crd certificaterequests.cert-manager.io',
            cstderr=True, cstdout=True)
        run('kubectl', 'get crd certificates.cert-manager.io',
            cstderr=True, cstdout=True)
        run('kubectl', 'get crd clusterissuers.cert-manager.io',
            cstderr=True, cstdout=True)
    except Exception:
        warning('cert-manager CRD not found. Installing cert-manager.')
        certmanager('apply', tag=REQ_VERSIONS['cert-manager']['DEFAULT'])
    else:
        message('cert-manager CRD found in cluster.')

    _, img, _= run('kubectl', f'-n cert-manager get deployment cert-manager -o jsonpath={{.spec.template.spec.containers[0].image}}',
                   cstderr=True, cstdout=True)
    check_component_version('cert-manager', img.decode('ascii').split(':')[1])

    print('Checking secret-agent operator and related CRDs:', end=' ')
    try:
        run('kubectl', 'get crd secretagentconfigurations.secret-agent.secrets.forgerock.io',
            cstderr=True, cstdout=True)
    except Exception as _e:
        warning('secret-agent CRD not found. Installing secret-agent.')
        secretagent('apply', tag=REQ_VERSIONS['secret-agent']['DEFAULT'])
    else:
        message('secret-agent CRD found in cluster.')
        message('\nChecking secret-agent operator is running...')
        run('kubectl', 'wait --for=condition=Established crd secretagentconfigurations.secret-agent.secrets.forgerock.io --timeout=30s')
        run('kubectl', '-n secret-agent-system wait --for=condition=available deployment  --all --timeout=120s')
        try:
            run('kubectl', '-n secret-agent-system get pod -l app.kubernetes.io/name=secret-agent-manager --field-selector=status.phase==Running')
        except Exception as e:
            error(f'Could not find a running secret-agent pod. See the following error: {e}')
            sys.exit(1)
        message('secret-agent operator is running')

    _, img, _ = run('kubectl', f'-n secret-agent-system get deployment secret-agent-controller-manager -o jsonpath={{.spec.template.spec.containers[0].image}}',
                    cstderr=True, cstdout=True)
    check_component_version('secret-agent', img.decode('ascii').split(':')[1])

    if not legacy and operator:
        print('Checking ds-operator and related CRDs:', end=' ')
        try:
            run('kubectl', 'get crd directoryservices.directory.forgerock.io',
                cstderr=True, cstdout=True)
        except Exception:
            warning('ds-operator CRD not found. Installing ds-operator.')
            run('kubectl', f'delete crd directorybackups.directory.forgerock.io --ignore-not-found=true')
            run('kubectl', f'delete crd directoryrestores.directory.forgerock.io --ignore-not-found=true')
            dsoperator('apply', tag=REQ_VERSIONS['ds-operator']['DEFAULT'])
        else:
            message('ds-operator CRD found in cluster.')

        _, img, _ = run('kubectl', f'-n fr-system get deployment ds-operator-ds-operator -o jsonpath={{.spec.template.spec.containers[0].image}}',
                        cstderr=True, cstdout=True)
        check_component_version('ds-operator', img.decode('ascii').split(':')[1])

    print()

# Copyright (c) 2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Utility wrapping the kubectl command
"""

# Lib imports
import subprocess

# Framework imports
from utils import logger


KUBECTL_COMMAND = 'kubectl'


def exec(namespace, sub_command):
    """
    Run a kubectl exec command
    :param namespace: kubernetes namespace
    :param sub_command: command to run
    :return: (stdout, stderr) from running the command
    """

    command_list = [KUBECTL_COMMAND, '-n', namespace, 'exec'] + sub_command
    command = ' '.join(command_list)
    return __run_cmd_process(command)


def cp_from_pod(namespace, pod_name, source, destination, container_name):
    """
    Copy from source on pod to local destination.
    :param namespace: kubernetes namespace
    :param pod_name: Name of pod
    :param source: Path to items to be copied
    :param destination: Path of where to copy files to.
    :param product_type: Name of container within pod.
    :return: (stdout, stderr) from running the command
    """

    logger.debug('Copying {source} to {destination} for {container_name}:{pod_name} in {namespace}'.format(
        source=source, destination=destination, container_name=container_name, pod_name= pod_name, namespace=namespace))
    source_command = '{namespace}/{pod_name}:{source}'.format(namespace=namespace, pod_name=pod_name, source=source)
    command = ' '.join([KUBECTL_COMMAND, 'cp', source_command, destination, '-c', container_name])
    return __run_cmd_process(command)


def get_product_component_names(namespace, product_type):
    """
    Get the names of the pods for the given platform product
    :param namespace: Name of kubernetes namespace
    :param product_type: Name of platform product
    :return: List of pod names
    """

    command = ' '.join([KUBECTL_COMMAND, '-n', namespace, 'get', 'pods',
                        '--selector=component={product_type}'.format(product_type=product_type)])
    stdout, ignored = __run_cmd_process(command)
    pod_names = []
    for line in stdout:
        logger.debug('Found component {component}'.format(component=line))
        line_contents = line.split(' ')
        if line_contents[0] != 'NAME' and len(line_contents) > 1:
            pod_names.append(line_contents[0])
    return pod_names


def __run_cmd_process(cmd):
    """
    Run a command as process.  Checks the return code.
    :param cmd: command to run
    :return: Duple of string lists (stdout, stderr)
    """

    logger.debug('Running following command as process: {cmd}'.format(cmd=cmd))
    response = subprocess.Popen(
        cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    stdout, stderr = response.communicate()

    assert response.returncode == 0, ' Unexpected return code {return_code} from cmd {stderr}'.format(
        return_code=response.returncode, stderr=stderr)
    return stdout.split('\n'), stderr.split('\n')

# Copyright (c) 2016-2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Utility wrapping the kubectl command
"""

# Lib imports
import subprocess
from kubernetes import client, config

# Framework imports
from utils import logger


KUBECTL_COMMAND = 'kubectl'


def exec(namespace, command):
    """
    Run a kubectl exec command
    :param command: command to run
    :return: (stdout, stderr) from running the command
    """
    command = ' '.join([KUBECTL_COMMAND, '-n', namespace, 'exec', command])
    return __run_cmd_process(command)


def get_product_pod_names(namespace, product):
    """
    Get the names of the pods for the given platform product
    :param product: Name of platform product
    :param namespace: Name of kubernetes namespace
    :return: List of pod names
    """
    pods = __get_namespaced_pods(namespace)
    pod_names = []
    for pod in pods.items:
        pod_name = pod.metadata.name
        if product in pod_name:
            pod_names.append(pod_name)
    return pod_names


def __get_namespaced_pods(namespace):

    config.load_kube_config()
    k8s_client = client.CoreV1Api()
    pods = k8s_client.list_namespaced_pod(namespace)
    for pod in pods.items:
        logger.debug('%s\t%s\t%s' % (pod.status.pod_ip, pod.metadata.namespace, pod.metadata.name))
    return pods


def __run_cmd_process(cmd):
    """
    Run a command as process.  Checks the return code.
    :param cmd: command to run
    :return: (stdout, stderr)
    """
    logger.debug('Running following command as process: ' + cmd)
    response = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    stdout, stderr = response.communicate()
    assert response.returncode == 0, ' Unexpected return code from Popen() ' + stderr
    return (stdout.split('\n'), stderr.split('\n'))

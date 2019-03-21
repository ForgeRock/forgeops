from logging import INFO, WARNING, ERROR, DEBUG
from subprocess import Popen, PIPE
from app.lib.log import get_logger

# STDOUT logging as this is intended to run in docker


class ClusterController(object):
    """
    Custom wrapper around kubectl and helm libraries.
    Helm and kubectl must be installed and present in PATH (usually /usr/bin)
    This class doesn't solve cluster configuration or connection. Cluster connection must be working
    before using this cluster. Ensure this by calling simple kubectl command(e.g. kubectl get nodes).
    """
    def __init__(self):
        self.kubectl_cmd = 'kubectl'
        self.helm_cmd = 'helm'
        self.namespace = 'smoke'

        # Logger settings TODO - Move this to common lib to make settings easier
        self.logger = get_logger(self.__class__.__name__)

    # Base methods

    def helm(self, args):
        """
        Runs helm command. This expects helm to be present in path
        :param args: Helm args to run
        :return: string output from stdout/stderr
        """
        self.logger.log(level=INFO, msg='Running helm command with following args: ' + str(args))
        cmd = [self.helm_cmd] + args
        out = self.run_cmd(cmd)
        return str(out)

    def kubectl(self, args):
        """
        Runs kubectl command. This expects kubectl to be present in path
        :param args: Kubectl args to run
        :return: String output from stdout/stderr
        """
        cmd = [self.kubectl_cmd, '-n=' + self.namespace] + args
        return self.run_cmd(cmd=cmd)

    def set_namespace(self, namespace):
        """
        Sets namespace
        :param namespace: Namespace to work in
        """
        self.logger.log(INFO, "Setting namespace to: " + namespace)
        self.namespace = namespace

    def run_cmd_process(self, cmd):
        """
        Useful for getting flow output
        :param cmd: command to run
        :return: Process handle
        """
        self.logger.log(INFO, 'Running following command as process: ' + str(cmd))
        p = Popen(args=cmd, stdout=PIPE, stderr=PIPE)
        return p

    def run_cmd(self, cmd):
        """
        Uses subprocess to call kubectl or helm call
        :param cmd with arguments to run
        :return: output
        """
        self.logger.log(INFO, "Running command: " + str(cmd))
        p = Popen(args=cmd, stdout=PIPE, stderr=PIPE, universal_newlines=True)
        out, err = p.communicate()
        if err:
            self.logger.log(level=ERROR, msg="Error when running cmd: " + str(err))
        self.logger.log(level=INFO, msg="Cmd successful. Output: " + str(out))
        return str(out)

    # Helper methods

    def get_pods(self):
        """
        Gets a list of pods in namespace
        :return: Returns list of pods in namespace
        """
        return self.get_k8s_obj('pods')

    def get_services(self):
        """
        Gets a list of services running in namespace
        :return: List of services in namespace
        """
        return self.get_k8s_obj('services')

    def get_deployments(self):
        """
                Gets a list of services running in namespace
                :return: List of services in namespace
                """
        return self.get_k8s_obj('deployments')

    def get_stateful_sets(self):
        return self.get_k8s_obj('statefulset')

    def get_k8s_obj(self, obj):
        out = self.kubectl(['get', obj, '-o=name'])
        ret = []
        svcs = str(out).split('\n')[:-1]
        for svc in svcs:
            ret.append(svc.split('/')[1])
        return ret

    def get_helm_charts(self):
        """
        Gets a list of charts in namespace
        :return: List of charts in namespace
        """
        out = self.helm(['list', '-q', '--namespace=' + self.namespace])
        out = str(out).split('\n')[:-1]
        return out

    def deploy_helm_chart(self, path, chart_name, custom_yaml):
        """
        Deploys helm chart
        :param path: Path to helm chart files
        :param chart_name: Name of the chart
        :param custom_yaml: Path to custom yaml file to override default chart values
        :return: Output of cmd
        """
        out = self.helm(['install', '--name=' + self.namespace + '-' + chart_name, '--namespace=' +
                         self.namespace, '-f=' + custom_yaml, path])
        return out

    def delete_helm_chart(self, chart_name):
        """
        Deletes helm chart
        :param chart_name: Chart name to delete
        :return: Output of cmd
        """
        out = self.helm(['delete', '--purge', chart_name])
        return out


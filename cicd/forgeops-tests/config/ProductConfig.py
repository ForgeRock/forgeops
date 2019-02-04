"""
Product config class for tests. Parses env variables into classes and provides them to tests
Set env variables to override default ones before running tests

Also provides useful generated variables for products (rest endpoints url, etc...)

"""
# Lib imports
import os
import time
import socket

# Framework imports
from utils import logger
import utils.cmd

# Global flag to enable/disable verification of certificates
try:
    SSL_VERIFY = os.environ['SSL_VERIFY']
except KeyError:
    SSL_VERIFY = False


def is_cluster_mode():
    return 'CLUSTER_NAME' in os.environ


def is_minikube_context():
    out, err = utils.cmd.run_cmd('kubectl config current-context')
    return out.decode("utf-8").strip() == 'minikube'


def tests_namespace():
    if 'TESTS_NAMESPACE' in os.environ:
        return os.environ['TESTS_NAMESPACE']
    else:
        return 'smoke'


def tests_domain():
    if 'TESTS_DOMAIN' in os.environ:
        return os.environ['TESTS_DOMAIN'].lstrip('.')
    else:
        return 'forgeops.com'


def base_url():
    protocol = 'http'
    if is_minikube_context():
        protocol = 'https'
    return '%s://%s.iam.%s' % (protocol, tests_namespace(), tests_domain())


class AMConfig(object):
    def __init__(self):
        self.am_url = '%s/am' % base_url()

        if 'AM_ADMIN_PWD' in os.environ:
            self.amadmin_pwd = os.environ['AM_ADMIN_PWD']
        else:
            self.amadmin_pwd = 'password'

        self.am_realm = "/"
        self.rest_authn_url = self.am_url + '/json/authenticate?realm=%s' % self.am_realm
        self.rest_oauth2_authz_url = self.am_url + '/oauth2/authorize'
        self.rest_oauth2_access_token_url = self.am_url + '/oauth2/access_token?realm=%s' % self.am_realm
        self.ssl_verify = SSL_VERIFY


class IDMConfig(object):
    def __init__(self):
        self.idm_url = '%s/openidm' % base_url()

        if 'IDM_ADMIN_USERNAME' in os.environ:
            self.idm_admin_username = os.environ['IDM_ADMIN_USERNAME']
        else:
            self.idm_admin_username = 'openidm-admin'

        if 'IDM_ADMIN_PWD' in os.environ:
            self.idm_admin_pwd = os.environ['IDM_ADMIN_PWD']
        else:
            self.idm_admin_pwd = 'openidm-admin'

        self.rest_ping_url = self.idm_url + '/info/ping'
        self.rest_managed_user_url = self.idm_url + '/managed/user'
        self.rest_selfreg_url = self.idm_url + '/selfservice/registration'
        self.rest_selfpwreset_url = self.idm_url + '/selfservice/reset'
        self.ssl_verify = SSL_VERIFY

    def get_admin_headers(self, headers):
        """
        Update provided headers with admin headers
        :param headers: Headers to update with admin headers
        :return: updated headers
        """
        admin_headers = {'X-OpenIDM-Username': self.idm_admin_username,
                         'X-OpenIDM-Password': self.idm_admin_pwd}
        return {**admin_headers, **headers}


class IGConfig(object):
    def __init__(self):
        self.ig_url = '%s/ig' % base_url()
        self.ssl_verify = SSL_VERIFY


class DSConfig(object):
    def __init__(self):
        self.reserved_ports = []
        if is_cluster_mode():
            self.ds0_url = 'http://userstore-0.userstore.%s.svc.cluster.local:8080' % tests_namespace()
            self.ds1_url = 'http://userstore-1.userstore.%s.svc.cluster.local:8080' % tests_namespace()
        else:
            self.helm_cmd = 'kubectl'
            self.ds0_local_port = self.get_free_port(8080)
            self.ds0_url = 'http://localhost:%s' % self.ds0_local_port
            self.ds1_local_port = self.get_free_port(8080)
            self.ds1_url = 'http://localhost:%s' % self.ds1_local_port

        self.ds0_rest_ping_url = self.ds0_url + '/alive'
        self.ds1_rest_ping_url = self.ds1_url + '/alive'
        self.ssl_verify = SSL_VERIFY

    def stop_ds_port_forward(self, instance_nb=0):
        if not is_cluster_mode():
            eval('self.ds%s_popen' % instance_nb).kill()

    def start_ds_port_forward(self, instance_nb=0):
        if not is_cluster_mode():
            ds_pod_name = 'userstore-%s' % instance_nb
            ds_local_port = eval('self.ds%s_local_port' % instance_nb)
            cmd = self.helm_cmd + ' --namespace %s port-forward pod/%s %s:8080' % \
                  (tests_namespace(), ds_pod_name, ds_local_port)
            ds_popen = utils.cmd.run_cmd_process(cmd)

            duration = 60
            start_time = time.time()
            while time.time() - start_time < duration:
                soc = socket.socket()
                result = soc.connect_ex(("", ds_local_port))
                soc.close()
                if result != 0:
                    logger.warning('Port-forward for pod %s on port %s not ready, waiting 5s...' %
                                   (ds_pod_name, ds_local_port))
                    time.sleep(5)
                else:
                    logger.info('Port-forward for pod %s on port %s is ready' % (ds_pod_name, ds_local_port))
                    return ds_popen

            raise Exception('Port-forward for pod %s on port %s not ready after %ss' %
                            (ds_pod_name, ds_local_port, duration))

    def get_free_port(self, initial_port=8080):
        max_range = 1000
        for port_value in range(initial_port, initial_port + max_range):
            if port_value in self.reserved_ports:
                continue
            try:
                soc = socket.socket()
                result = soc.connect_ex(("", port_value))
                soc.close()
                if result != 0:
                    self.reserved_ports.append(port_value)
                    return port_value
            except Exception as exc:
                print('Fail to check port %s.  Got: %s' % (port_value, repr(exc)))

        raise Exception('Failed to get a free port in range [%s, %s]' % (initial_port, initial_port + max_range))


class NginxAgentConfig(object):
    def __init__(self):
        self.agent_url = 'https://nginx-agent.%s.%s' % (tests_namespace(), tests_domain())
        self.ssl_verify = SSL_VERIFY


class ApacheAgentConfig(object):
    def __init__(self):
        self.agent_url = 'https://apache-agent.%s.%s' % (tests_namespace(), tests_domain())
        self.ssl_verify = SSL_VERIFY

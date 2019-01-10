"""
Product config class for tests. Parses env variables into classes and provides them to tests
Set env variables to override default ones before running tests

Also provides useful generated variables for products (rest endpoints url, etc...)

"""
# Lib imports
import os
import subprocess

# Global flag to enable/disable verification of certificates
try:
    SSL_VERIFY = os.environ['SSL_VERIFY']
except KeyError:
    SSL_VERIFY = False


def is_cluster_mode():
    return 'CLUSTER_NAME' in os.environ


def tests_namespace():
    if 'TESTS_NAMESPACE' in os.environ:
        return os.environ['TESTS_NAMESPACE']
    else:
        return 'smoke'


def tests_domain():
    if 'TESTS_DOMAIN' in os.environ:
        return os.environ['TESTS_DOMAIN']
    else:
        return 'forgeops.com'


class AMConfig(object):
    def __init__(self):
        self.am_url = 'https://login.%s.%s' % (tests_namespace(), tests_domain())

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
        self.idm_url = 'https://openidm.%s.%s/openidm' % (tests_namespace(), tests_domain())

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
        self.ig_url = 'https://openig.%s.%s' % (tests_namespace(), tests_domain())
        self.ssl_verify = SSL_VERIFY


class DSConfig(object):
    def __init__(self):
        if is_cluster_mode():
            self.ds0_url = 'https://userstore-0.userstore:8080'
            self.ds1_url = 'https://userstore-1.userstore:8080'
        else:
            self.helm_cmd = 'kubectl'
            (self.ds0_url, self.ds0_popen) = self.start_ds_port_forward(instance_nb=0)
            (self.ds1_url, self.ds1_popen) = self.start_ds_port_forward(instance_nb=1)

        self.ds0_rest_ping_url = self.ds0_url + '/alive'
        self.ds1_rest_ping_url = self.ds1_url + '/alive'
        self.ssl_verify = SSL_VERIFY

    def stop_ds_port_forward(self, instance_nb=0):
        if not is_cluster_mode():
            eval('self.ds%s_popen' % instance_nb).kill()

    def start_ds_port_forward(self, instance_nb=0):
        ds_local_port = 8080 + instance_nb
        cmd = self.helm_cmd + ' --namespace %s port-forward pod/userstore-%s %s:8080' % \
            (tests_namespace(), instance_nb, ds_local_port)
        ds_popen = self.run_cmd_process(cmd)
        ds_url = 'http://localhost:%s' % ds_local_port
        return ds_url, ds_popen

    @staticmethod
    def run_cmd_process(cmd):
        """
        Useful for getting flow output
        :param cmd: command to run
        :return: Process handle
        """
        print('Running following command as process: ' + cmd)
        popen = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return popen


class NginxAgentConfig(object):
    def __init__(self):
        self.agent_url = 'https://nginx-agent.%s.%s' % (tests_namespace(), tests_domain())
        self.ssl_verify = SSL_VERIFY


class ApacheAgentConfig(object):
    def __init__(self):
        self.agent_url = 'https://apache-agent.%s.%s' % (tests_namespace(), tests_domain())
        self.ssl_verify = SSL_VERIFY

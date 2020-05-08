"""
Product config class for tests. Parses env variables into classes and provides them to tests
Set env variables to override default ones before running tests

Also provides useful generated variables for products (rest endpoints url, etc...)

"""
# Lib imports
import os
import re
import time
import socket

import requests
from requests import post, get, delete

# Framework imports
from lib.utils import logger, rest, cmd

# Global flag to enable/disable verification of certificates
try:
    SSL_VERIFY = os.environ['SSL_VERIFY']
except KeyError:
    SSL_VERIFY = False


def is_cluster_mode():
    return 'CLUSTER_NAME' in os.environ


def is_minikube_context():
    out, _err = cmd.run_cmd('kubectl config current-context')
    return out.decode("utf-8").strip() == 'minikube'


def tests_namespace():
    return os.environ.get('TESTS_NAMESPACE', 'smoke').lstrip('.')

def tests_subdomain():
    return os.environ.get('TESTS_SUBDOMAIN', 'iam').lstrip('.')

def tests_domain():
    return os.environ.get('TESTS_DOMAIN', 'forgeops.com').lstrip('.')


def base_url():
    return 'https://{}.{}.{}'.format(tests_namespace(), tests_subdomain(), tests_domain())


class AMConfig(object):
    def __init__(self):
        self.am_url = '%s/am' % base_url()

        self.amadmin_pwd = os.environ['AM_ADMIN_PWD']

        self.am_realm = "/"
        # Use the console auth module /json/authenticate?authIndexType=service&authIndexValue=adminconsoleservice
        self.rest_authn_admin_url = self.am_url + '/json/authenticate?authIndexType=service&authIndexValue=adminconsoleservice'
        self.rest_authn_url = self.am_url + '/json/authenticate?realm=%s' % self.am_realm
        self.rest_oauth2_authz_url = self.am_url + '/oauth2/authorize'
        self.rest_oauth2_access_token_url = self.am_url + '/oauth2/access_token?realm=%s' % self.am_realm
        self.ssl_verify = SSL_VERIFY

    def create_user(self, username, password='password'):
        headers = {'X-OpenAM-Username': 'amadmin', 'X-OpenAM-Password': self.amadmin_pwd,
                   'Content-Type': 'application/json', 'Accept-API-Version': 'resource=2.0, protocol=1.0'}

        logger.test_step('Admin login')
        response = post(verify=self.ssl_verify, url=self.rest_authn_admin_url, headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)

        admin_token = response.json()["tokenId"]

        headers = {'iPlanetDirectoryPro': admin_token, 'Content-Type': 'application/json',
                   'Accept-API-Version': 'resource=3.0, protocol=2.1'}
        user_data = {'username': username,
                     'userpassword': password,
                     'mail': f'{username}@forgerock.com'}

        logger.test_step('Expecting test user to be created - HTTP-201')
        response = post(verify=self.ssl_verify, url=self.am_url + '/json/realms/root/users/?_action=create',
                        headers=headers, json=user_data)
        rest.check_http_status(http_result=response, expected_status=201)

    def delete_user(self, username):
        headers = {'X-OpenAM-Username': 'amadmin', 'X-OpenAM-Password': self.amadmin_pwd,
                   'Content-Type': 'application/json', 'Accept-API-Version': 'resource=2.0, protocol=1.0'}

        logger.test_step('Admin login')
        response = post(verify=self.ssl_verify, url=self.rest_authn_admin_url, headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)

        admin_token = response.json()["tokenId"]

        headers = {'iPlanetDirectoryPro': admin_token, 'Content-Type': 'application/json',
                   'Accept-API-Version': 'resource=3.0, protocol=2.1'}

        logger.test_step('Expecting test user to be deleted - HTTP-200')
        response = delete(verify=self.ssl_verify, url=self.am_url + f'/json/realms/root/users/{username}',
                          headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)

    def login_user(self, username, password):
        headers = {'X-OpenAM-Username': username,
                   'X-OpenAM-Password': password,
                   'Content-Type': 'application/json',
                   'Accept-API-Version': 'resource=2.0, protocol=1.0'}

        logger.test_step(f'User {username} authn REST - AM')
        response = post(verify=self.ssl_verify, url=self.rest_authn_url, headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)


class IDMConfig(object):
    def __init__(self):
        self.idm_url = '%s/openidm' % base_url()

        self.idm_admin_username = os.environ.get('IDM_ADMIN_USERNAME', 'openidm-admin')
        self.idm_admin_pwd = os.environ['IDM_ADMIN_PWD']

        self.rest_ping_url = self.idm_url + '/info/ping'
        self.rest_managed_user_url = self.idm_url + '/managed/user'
        self.rest_selfreg_url = self.idm_url + '/selfservice/registration'
        self.rest_selfpwreset_url = self.idm_url + '/selfservice/reset'
        self.admin_oauth_client = 'idm-admin-ui'
        self.admin_oauth_redirect_url = f'{base_url()}/admin/appAuthHelperRedirect.html'
        self.admin_oauth_scopes = 'openid'
        self.bearer_token = None

        self.ssl_verify = SSL_VERIFY

    def create_user(self, payload):
        headers = self.get_admin_headers({
            'Content-Type': 'application/json',
        })

        logger.test_step('Create test user')
        response = post(verify=self.ssl_verify, url=f'{self.rest_managed_user_url}?_action=create',
                        headers=headers, data=payload)
        rest.check_http_status(http_result=response, expected_status=201)

    def delete_user(self, user_id):
        headers = self.get_admin_headers({
            'Content-Type': 'application/json',
            'if-match': '*',
        })

        logger.test_step('Delete test user')
        response = delete(verify=self.ssl_verify, url=f'{self.rest_managed_user_url}/{user_id}',
                          headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)

    def get_userid_by_name(self, name):
        """
        Get first matching user_id by username.
        :param name: username
        :return: user id
        """
        headers1 = self.get_admin_headers({
            'Content-Type': 'application/json'
        })
        response = get(verify=self.ssl_verify, url=self.rest_managed_user_url +
                                                          f'?_queryFilter=username+eq+"{name}"&_fields=_id',
                       headers=headers1).json()

        if response['resultCount'] > 0:
            return response['result'][0]['_id']

    def get_bearer_token(self):
        """
        When IDM is integrated with AM, we need bearer token for being able to do admin stuff.
        This do following:
            - login into AM as amadmin
            - do OAuth2 flow with idm-admin-ui oauth2 client
            - return bearer token
        :return: Admin bearer token
        """
        if self.bearer_token is not None:
            return self.bearer_token

        amcfg = AMConfig()

        # GetAMAdminLogin
        s = requests.session()
        headers = {
            'X-OpenAM-Username': 'amadmin',
            'X-OpenAM-Password': amcfg.amadmin_pwd,
            'Accept-API-Version': 'resource=2.0, protocol=1.0',
            'Content-Type': 'application/json'
        }
        params = {
            'redirect_uri': self.admin_oauth_redirect_url,
            'client_id': self.admin_oauth_client,
            'response_type': 'code',
            'scope': self.admin_oauth_scopes,
        }

        token = s.post(amcfg.rest_authn_admin_url, headers=headers, verify=self.ssl_verify).json()['tokenId']
        data = {"decision": "Allow", 'csrf': token}
        headers = {
            'Content-Type': 'application/x-www-form-urlencoded',
            'accept-api-version': 'resource=2.1'
        }
        r_loc = s.post(amcfg.rest_oauth2_authz_url, data=data, verify=self.ssl_verify, headers=headers, params=params,
                       allow_redirects=False).headers['Location']

        auth_code = re.findall('(?<=code=)(.+?)(?=&)', r_loc)
        print(f'Got oauth2 code: {auth_code}')

        headers = {
            'Accept-API-Version': 'resource=2.0, protocol=1.0',
            'Content-Type': 'application/x-www-form-urlencoded'
        }

        data = {
            'grant_type': 'authorization_code',
            'code': auth_code[0],
            'redirect_uri': self.admin_oauth_redirect_url,
            'client_id': self.admin_oauth_client
        }

        logger.test_step('Oauth2 get access-token REST')
        response = s.post(verify=amcfg.ssl_verify, url=amcfg.rest_oauth2_access_token_url,
                          data=data, headers=headers)
        self.bearer_token = response.json()['access_token']
        return self.bearer_token

    def get_admin_headers(self, headers=None):
        if headers is None:
            headers = {}

        admin_headers = {
            'authorization': f'Bearer {self.get_bearer_token()}'
        }
        return {**admin_headers, **headers}


class IGConfig(object):
    def __init__(self):
        self.ig_url = '%s/ig' % base_url()
        self.ssl_verify = SSL_VERIFY


class DSConfig(object):
    def __init__(self):
        if is_cluster_mode():
            self.userstore0_url = 'http://userstore-0.userstore.%s.svc.cluster.local:8080' % tests_namespace()
            self.userstore1_url = 'http://userstore-1.userstore.%s.svc.cluster.local:8080' % tests_namespace()
            self.ctsstore0_url = 'http://ctsstore-0.ctsstore.%s.svc.cluster.local:8080' % tests_namespace()
            self.confistore0_url = 'http://configstore-0.configstore.%s.svc.cluster.local:8080' % tests_namespace()
        else:
            self.helm_cmd = 'kubectl'
            self.userstore0_local_port = self.get_free_port(8080)
            self.userstore0_url = 'http://localhost:%s' % self.userstore0_local_port
            self.userstore1_local_port = self.get_free_port(8080)
            self.userstore1_url = 'http://localhost:%s' % self.userstore1_local_port
            self.ctsstore0_local_port = self.get_free_port(8080)
            self.ctsstore0_url = 'http://localhost:%s' % self.ctsstore0_local_port
            self.configstore0_local_port = self.get_free_port(8080)
            self.configstore0_url = 'http://localhost:%s' % self.configstore0_local_port

        self.userstore0_rest_ping_url = self.userstore0_url + '/alive'
        self.userstore1_rest_ping_url = self.userstore1_url + '/alive'
        self.ctsstore0_rest_ping_url = self.ctsstore0_url + '/alive'
        self.configstore0_rest_ping_url = self.configstore0_url + '/alive'
        self.ssl_verify = SSL_VERIFY
        self.reserved_ports = []

    def stop_ds_port_forward(self, instance_name='userstore', instance_nb=0):
        if not is_cluster_mode():
            eval('self.%s%s_popen' % (instance_name, instance_nb)).kill()

    def start_ds_port_forward(self, instance_name='userstore', instance_nb=0):
        if not is_cluster_mode():
            ds_pod_name = '%s-%s' % (instance_name, instance_nb)
            ds_local_port = eval('self.%s%s_local_port' % (instance_name, instance_nb))
            command = self.helm_cmd + ' --namespace %s port-forward pod/%s %s:8080' % \
                  (tests_namespace(), ds_pod_name, ds_local_port)
            ds_popen = cmd.run_cmd_process(command)

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


class EndUserUIConfig(object):
    def __init__(self):
        self.ui_url = f'{base_url()}/enduser/#/dashboard'


class NginxAgentConfig(object):
    def __init__(self):
        self.agent_url = 'https://nginx-agent.%s.%s' % (tests_namespace(), tests_domain())
        self.ssl_verify = SSL_VERIFY


class ApacheAgentConfig(object):
    def __init__(self):
        self.agent_url = 'https://apache-agent.%s.%s' % (tests_namespace(), tests_domain())
        self.ssl_verify = SSL_VERIFY


if __name__ == '__main__':
    idmcfg = IDMConfig()
    idmcfg.get_bearer_token()

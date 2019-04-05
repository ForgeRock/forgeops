"""
AM Simple runtime config library
"""
import time

from requests import get, post, put
import requests

requests.packages.urllib3.disable_warnings()


class AMConfig(object):
    def __init__(self):
        self.am_fqdn = 'openam'
        self.am_url = f'http://{self.am_fqdn}:80/am'
        self.wait_for_am()
        self.admin_token = self.admin_login()

    # UTILITY METHODS
    def wait_for_am(self):
        while 1:
            try:
                request = get(url=self.am_url, verify=False)
                if request.status_code is 200:
                    print('AM ready for runtime config')
                    return
                else:
                    print("AM not ready yet, waiting for 10 seconds")
                    time.sleep(10)
            except Exception:

                pass

    def admin_login(self, password='password'):
        headers = {
            'X-OpenAM-Username': 'amadmin',
            'X-OpenAM-Password': password,
            'Accept-API-Version': 'resource=2.0, protocol=1.0'
        }

        login_request = post(f'{self.am_url}/json/authenticate', headers=headers, verify=False)
        token = login_request.json()['tokenId']
        print(f'Have admin access token: {token}')
        return token

    @property
    def admin_headers(self):
        return {'iPlanetDirectoryPro': self.admin_token,
                'Accept-API-Version': 'resource=1.0',
                'Content-Type': 'application/json'}

    # OAUTH2 RELATED CONFIG
    def create_oauth2_provider(self, custom_config=None):
        """
        Creates a oauth2 provider in root realm
        :param custom_config: If specified, custom config values will be used instead of default ones.
        """
        if custom_config is not None:
            config = custom_config
        else:
            template_request = post(
                url=f'{self.am_url}/json/realms/root/realm-config/services/oauth-oidc?_action=template',
                headers=self.admin_headers, verify=False)
            config = template_request.json()

        create_request = post(url=f'{self.am_url}/json/realms/root/realm-config/services/oauth-oidc?_action=create',
                              headers=self.admin_headers, verify=False,
                              json=config)
        print(create_request.status_code)

    def create_oauth2_client(self, client_name='oauth2', custom_config=None):
        """
        Method to create oauth2 client profile
        :param client_name: Name of the client
        :param custom_config: If specified, this will be used as payload. Expecting dictionary with values.
        """
        default_config = {
            '_id': 'oauth2',
            'coreOAuth2ClientConfig': {
                'defaultScopes': ['cn', 'mail'],
                'redirectionUris': ['http://fake.com'],
                'scopes': ['profile', 'uid'],
                'userpassword': 'password'
            }
        }

        if custom_config is not None:
            config = custom_config
        else:
            config = default_config

        create_request = put(url=f'{self.am_url}/json/realms/root/realm-config/agents/OAuth2Client/{client_name}',
                             headers=self.admin_headers, verify=False,
                             json=config)
        print(create_request.status_code)

    def create_policy_all_authenticated(self, name, resource, allow):
        """
        Simple example method to create policy to allow/deny all authenticated users to access resource
        :param name: Name of the policy
        :param resource: Resource url
        :param allow: True/false resource access
        """
        policy = {
            '_id': name,
            'name': name,
            'active': True,
            'description': '',
            'resources': [
                resource
            ],
            'applicationName': 'iPlanetAMWebAgentService',
            'actionValues': {
                'HEAD': allow,
                'DELETE': allow,
                'POST': allow,
                'GET': allow,
                'OPTIONS': allow,
                'PATCH': allow,
                'PUT': allow
            },
            'subject': {
                'type': 'AuthenticatedUsers'
            }
        }
        url = f'{self.am_url}/json/policies/{name}'
        policy_request = put(url=url, json=policy, headers=self.admin_headers, verify=False)
        print(policy_request.status_code)


if __name__ == '__main__':
    print('Doing minimal AM smoke test config')
    cfg = AMConfig()
    # cfg.create_oauth2_provider()
    cfg.create_oauth2_client()
    cfg.create_policy_all_authenticated(name='test-policy',
                                        resource='http://test-policy.com/test',
                                        allow=True)
    print('Runtime config finished')

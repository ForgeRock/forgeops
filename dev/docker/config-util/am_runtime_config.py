"""
AM Simple runtime config library
"""

import time
import argparse
import os
import json


from requests import get, post, put
import requests

requests.packages.urllib3.disable_warnings()


class AMConfig(object):
    def __init__(self,url):
        self.domain = os.getenv('DOMAIN', 'forgeops.com')
        self.admin_password = os.getenv('ADMIN_PASSWORD', 'password')
     
        # self.am_url = f'https://{self.am_fqdn}:443/am'
        # self.am_internal_url = 'http://openam:80/am'
        self.am_url = url
        self.wait_for_am()
        self.admin_token = self.admin_login()

    # UTILITY METHODS
    def wait_for_am(self):
        while 1:
            try:
                print(f'Wating for AM {self.am_url}')
                request = get(url=self.am_url, verify=False)
                if request.status_code is 200:
                    print('AM ready for runtime config')
                    return
                else:
                    print("AM not ready yet, waiting for 10 seconds")
                    time.sleep(10)
            except Exception as e:
                print(e.with_traceback())
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

    # Slurp a json file in amster format. Does search/replace on the string &{fqdn}
    def read_json(self,path,fqdn):
        with open(path) as jsonfile:
            text = jsonfile.read()
            # This is a hack - we only support FQDN replacement for now...
            text = text.replace(r'&{fqdn}', fqdn)
            json_data = json.loads(text)
            return json_data['data']

    # Import all config files for the root realm
    def import_realm_config(self,dir,fqdn):
         for filename in os.listdir(dir):
            data = self.read_json(f'{dir}/{filename}', fqdn)
            _type = data['_type']
            id = _type['_id']
            name = _type['name']
            if id == "LDAPv3ForOpenDS":
                self.put(f'{self.am_url}/json/realms/root/realm-config/services/id-repositories/{id}/{name}',data)
            else:
                self.put(f'{self.am_url}/json/realms/root/realm-config/services/{id}',data)
            # TODO: More error checking here...
            # else:
            #     print(f'I dont know how to import type {id}')

    #  Import oauth2 configs in amster format
    def import_oauth2_configs(self, dir, fqdn):
        for filename in os.listdir(dir):
            data = self.read_json(f'{dir}/{filename}',fqdn)
            id = data['_id']
            self.put(f'{self.am_url}/json/realms/root/realm-config/agents/OAuth2Client/{id}', data)

    def put(self,url,config):
        print(f'Put url={url}')
        create_request = put(url=url,headers=self.admin_headers, verify=False,json=config)
        print(create_request.status_code)
        
    def import_global_configs(self,dir,fqdn):
        for filename in os.listdir(dir):
            data = self.read_json(f'{dir}/{filename}',fqdn)
            _type = data['_type']
            id = _type['_id']
            self.put(f'{self.am_url}/json/global-config/services/{id}', data)

    def import_secrets_configs(self,dir,fqdn):
        for filename in os.listdir(dir):
            data = self.read_json(f'{dir}/{filename}',fqdn)
            _id = data['_id']
            _type = data['_type']['_id']
            self.put(f'{self.am_url}/json/global-config/secrets/stores/{_type}/{_id}', data)

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
        self.put(url=url, config=policy)
    

if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Configure AM')
    # This option is for debugging  / testing from your laptop. If you
    # run in the cluster you can omit this.
    parser.add_argument('--useFQDN', action='store_true', help='Use the external FQDN to configure AM, not the internal service')

    args = parser.parse_args()

    am_fqdn = os.getenv('FQDN', 'default.iam.forgeops.com')
    am_url = f'https://{am_fqdn}:443/am'
    if not args.useFQDN:
        am_url = 'http://openam:80/am'
    

    print(f'Doing minimal AM config with url {am_url} external fqdn {am_fqdn}')
    cfg = AMConfig(am_url)
    cfg.import_global_configs('./global', am_fqdn)
    cfg.import_realm_config('./realm',am_fqdn)
    cfg.import_oauth2_configs('./oauth2', am_fqdn)
    cfg.import_secrets_configs('./secrets', am_fqdn)

    cfg.create_policy_all_authenticated(name='test-policy',
                                        resource='http://test-policy.com/test',
                                        allow=True)
    print('Runtime config finished!')

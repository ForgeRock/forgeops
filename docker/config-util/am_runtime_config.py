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
    def __init__(self, url, fqdn, folder):
        self.domain = os.getenv('DOMAIN', 'forgeops.com')
        self.admin_password = os.getenv('ADMIN_PASSWORD', 'password')

        # self.am_url = f'https://smoke.iam.forgeops.com:443/am'
        # self.am_internal_url = 'http://am:80/am'
        self.am_url = url
        self.wait_for_am()
        self.admin_token = self.admin_login()
        self.config_dir = folder
        self.fqdn = fqdn
        self.entityMap = {
            "RestApis": "global-config/services",
            "PrometheusReporter": "global-config/services/monitoring/prometheus",
            "KeyStoreSecretStore": "global-config/secrets/stores/KeyStoreSecretStore",
            "FileSystemSecretStore": "global-config/secrets/stores/FileSystemSecretStore",
            "CtsDataStoreProperties": "global-config/servers",
            "DefaultCtsDataStoreProperties": "global-config/servers/server-default/properties/cts",
            "Authentication": "global-config/authentication",
            "DefaultAdvancedProperties": "global-config/servers/server-default/properties/advanced",
            "neoLdapService": "realms/root/realm-config/authentication/modules/ldap/neoLdapService"      
        }

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
            'accept-api-version': 'resource=1.0,protocol=2.0',
        }
        login_request = post(f'{self.am_url}/json/authenticate', headers=headers, verify=False)
        token = login_request.json()['tokenId']
        print(f'Have admin access token: {token}')
        return token

    @property
    def admin_headers(self):
        return {'iPlanetDirectoryPro': self.admin_token,
                'accept-api-version': 'protocol=1.0,resource=1.0',
                'Content-Type': 'application/json'}

    # This header is needed for CREST 2.0 PUT requests          
    # 'if-none-match' : '*',
    @property
    def admin_headers_crest2(self):
        return {'iPlanetDirectoryPro': self.admin_token,
                'accept-api-version': 'protocol=2.0,resource=1.0',
                'if-none-match': '*',
                'Content-Type': 'application/json'}

    # Slurp a json file in amster format/ - return just the data payload
    def read_json_data(self, path, fqdn):
        return self.read_json_full(path, fqdn)['data']

    #  search/replace on the string &{fqdn}
    def read_json_full(self, path, fqdn):
        with open(path) as jsonfile:
            text = jsonfile.read()
            text = text.replace(r'&{fqdn}', fqdn)
            json_data = json.loads(text)
            return json_data

    def put(self, url, config, headers):
        r = put(url=url, headers=headers, verify=False, json=config)
        print(f'Put url={url} status={r}')
        if r.status_code > 300:
            print(f'Error is {r.content} ')

    # Calculates the json path from the payload. 
    def type_to_url(self, payload):
        # payload contains a _type struct
        type = payload['metadata']['entityType']
        # The _id is the object type
        id = payload['data']['_id']
        u = self.entityMap[type]
        if (id == None or id.startswith("null")):
            return f'{self.am_url}/json/{u}'
        return f'{self.am_url}/json/{u}/{id}'

    # Import all config files for the root realm
    def import_realm_config(self):
        dir = f'{self.config_dir}/realm'
        for filename in os.listdir(dir):
            data = self.read_json_data(f'{dir}/{filename}', self.fqdn)
            _type = data['_type']
            id = _type['_id']
            name = _type['name']
            # /am/json/realm-config/services/id-repositories/LDAPv3ForForgeRockIAM/DS%20for%20ForgeRock%20IAM
            
            if id.startswith("LDAPv3"):
                self.put(f'{self.am_url}/json/realms/root/realm-config/services/id-repositories/{id}/{name}', data, self.admin_headers)
            elif name == "Core":
                self.put(f'{self.am_url}/json/realms/root/realm-config/authentication', data, self.admin_headers)
            else:
                self.put(f'{self.am_url}/json/realms/root/realm-config/services/{id}', data, self.admin_headers_crest2)
            # TODO: More error checking here...
            # else:
            #     print(f'I dont know how to import type {id}')

    def import_oauth2_configs(self):
        dir = f'{self.config_dir}/oauth2'
        for filename in os.listdir(dir):
            data = self.read_json_data(f'{dir}/{filename}', self.fqdn)
            id = data['_id']
            url = f'{self.am_url}/json/realms/root/realm-config/agents/OAuth2Client/{id}'
            self.put(url, data, self.admin_headers_crest2)

    def import_auth_modules(self):
        dir = f'{self.config_dir}/chains'
        for filename in os.listdir(dir):
            data = self.read_json_full(f'{dir}/{filename}', self.fqdn)
            _chainId = data['data']['_id']
            _chainConfig = data['data']['authChainConfiguration']
            url = f'{self.am_url}/json/realms/root/realm-config/authentication'
            # Create chain
            post(f'{url}/chains?_action=create', json={"_id" : _chainId}, headers=self.admin_headers)
            # Update chain configuration
            put(f'{url}/chains/{_chainId}', json={"authChainConfiguration": _chainConfig}, headers=self.admin_headers)
            # if filename == "Authentication.json":
            #     self.put(f'{self.am_url}/json/realms/root/realm-config/authentication', data, self.admin_headers)
            

    def import_global_configs(self):
        dir = f'{self.config_dir}/global'
        for filename in os.listdir(dir):
            data = self.read_json_full(f'{dir}/{filename}', self.fqdn)
            url = self.type_to_url(data)
            payload = data['data']
            # Remove the id from the payload - not required for PUT
            payload.pop('_id')
            self.put(url, payload, self.admin_headers)

    def import_policies(self):
        dir = f'{self.config_dir}/policies'
        for filename in os.listdir(dir):
            data = self.read_json_full(f'{dir}/{filename}', self.fqdn)
            _id = data['data']['_id']
            _type = data['metadata']['entityType'].lower()
            self.put(f'{self.am_url}/json/{_type}/{_id}', data['data'], self.admin_headers_crest2)


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Configure AM')
    # This option is for debugging  / testing from your laptop. If you
    # run in the cluster you can omit this. This lets you 
    # run against the ingress (external) URL, instead of the internal (http://am)
    # To use this export FQDN=default.iam.example.com; python3 ./am_runtime_config.py
    parser.add_argument('--useFQDN', action='store_true',
                        help='Use the external FQDN to configure AM, not the internal service')

    args = parser.parse_args()

    am_fqdn = os.getenv('FQDN', 'default.iam.forgeops.com')
    am_cfg_folder = os.getenv('CONFIG_FOLDER', 'configs/amidm')
    am_url = f'https://{am_fqdn}:443/am'
    if not args.useFQDN:
        am_url = 'http://am:80/am'

    print(f'Doing minimal AM config using {am_cfg_folder} with url {am_url} external fqdn {am_fqdn}')
    cfg = AMConfig(am_url, am_fqdn, am_cfg_folder)
    cfg.import_global_configs()
    #cfg.import_auth_chains()
    cfg.import_realm_config()
    cfg.import_oauth2_configs()
    cfg.import_policies()
    print('Runtime config finished!')

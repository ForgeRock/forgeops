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
        # self.am_internal_url = 'http://openam:80/am'
        self.am_url = url
        self.wait_for_am()
        self.admin_token = self.admin_login()
        self.config_dir = folder
        self.fqdn = fqdn
        self.entityMapper = {
            "rest" : "global-config/services",
            "prometheus" : "global-config/services/monitoring/prometheus",
            "KeyStoreSecretStore" :  "global-config/secrets/stores/KeyStoreSecretStore",
            "FileSystemSecretStore" : "global-config/secrets/stores/FileSystemSecretStore",
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
    
    def put(self, url, config):
        print(f'Put url={url}')
        create_request = put(url=url, headers=self.admin_headers, verify=False, json=config)
        print(create_request.status_code)

    # Calculates the json path from data payload. 
    def type_to_url(self,data):
        # payload contains a _type struct
        type = data['_type']
        # The _id is the object type
        _t = type['_id']
        # get the json path
        t = self.entityMapper[_t]
        # The object instance is the _id of the data field
        id = data['_id']
        return f'{self.am_url}/json/{t}/{id}'

    # Import all config files for the root realm
    def import_realm_config(self):
        dir = f'{self.config_dir}/realm'
        for filename in os.listdir(dir):
            data = self.read_json_data(f'{dir}/{filename}', self.fqdn)
            _type = data['_type']
            id = _type['_id']
            name = _type['name']
            if id == "LDAPv3ForOpenDS":
                self.put(f'{self.am_url}/json/realms/root/realm-config/services/id-repositories/{id}/{name}', data)
            else:
                self.put(f'{self.am_url}/json/realms/root/realm-config/services/{id}', data)
            # TODO: More error checking here...
            # else:
            #     print(f'I dont know how to import type {id}')

    def import_oauth2_configs(self):
        dir = f'{self.config_dir}/oauth2'
        for filename in os.listdir(dir):
            data = self.read_json_data(f'{dir}/{filename}', self.fqdn)
            id = data['_id']
            self.put(f'{self.am_url}/json/realms/root/realm-config/agents/OAuth2Client/{id}', data)

    def import_global_configs(self):
        dir = f'{self.config_dir}/global'
        for filename in os.listdir(dir):
            data = self.read_json_data(f'{dir}/{filename}', self.fqdn)
            url = self.type_to_url(data)
            self.put(url, data)

    def import_policies(self):
        dir =  f'{self.config_dir}/policies'
        for filename in os.listdir(dir):
            data = self.read_json_full(f'{dir}/{filename}', self.fqdn)
            _id = data['data']['_id']
            _type = data['metadata']['entityType'].lower()
            self.put(f'{self.am_url}/json/{_type}/{_id}', data['data'])

if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Configure AM')
    # This option is for debugging  / testing from your laptop. If you
    # run in the cluster you can omit this. This lets you 
    # run against the ingress (external) URL, instead of the internal (http://openam)
    # To use this export FQDN=default.iam.example.com; python3 ./am_runtime_config.py
    parser.add_argument('--useFQDN', action='store_true',
                        help='Use the external FQDN to configure AM, not the internal service')

    args = parser.parse_args()

    am_fqdn = os.getenv('FQDN', 'default.iam.forgeops.com')
    am_cfg_folder = os.getenv('CONFIG_FOLDER', 'configs/amidm')
    am_url = f'https://{am_fqdn}:443/am'
    if not args.useFQDN:
        am_url = 'http://openam:80/am'

    print(f'Doing minimal AM config using {am_cfg_folder} with url {am_url} external fqdn {am_fqdn}')
    cfg = AMConfig(am_url, am_fqdn, am_cfg_folder)
    cfg.import_global_configs()
    cfg.import_realm_config()
    cfg.import_oauth2_configs()
    cfg.import_policies()
    print('Runtime config finished!')

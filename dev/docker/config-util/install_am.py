#!/usr/bin/env python3
"""
AM Install script. Substitution for amster install.
Performs initial configuration.

For customization, look into am_install.cfg
"""
import os
import threading
import configparser
import time
import sys

import urllib3

from requests import post, get

urllib3.disable_warnings()

# Load env properties

DOMAIN = os.getenv('DOMAIN', 'forgeops.com')
ADMIN_PASSWORD = os.getenv('ADMIN_PASSWORD', 'password')
AM_FQDN = os.getenv('FQDN', 'default.iam.forgeops.com')

# List of AM initial configuration properties
properties = {
    'DEPLOYMENT_URI': 'am',
    'SERVER_URL': 'http://openam:80',
    'COOKIES_DOMAIN': DOMAIN,
    'BASE_DIR': '/home/forgerock/openam',
    'locale': 'en_US',
    'AM_ENC_KEY': 'C00lBeans',
    'ADMIN_PWD': ADMIN_PASSWORD,
    'ADMIN_CONFIRM_PWD': ADMIN_PASSWORD,
    'DIRECTORY_SERVER': 'ds-idrepo',
    'DIRECTORY_PORT': '1389',
    'DS_DIRMGRPASSWD': 'password',
    'DIRECTORY_ADMIN_PORT': '4444',
    'ROOT_SUFFIX': 'ou=am-config',
    'DS_DIRMGRDN': 'uid=admin',
    'DIRECTORY_SSL': 'SIMPLE',
    'DATA_STORE': 'external',
    'USERSTORE_TYPE': 'LDAPv3ForOpenDS',
    'USERSTORE_MGRDN': 'uid=admin',
    'USERSTORE_HOST': 'ds-idrepo',
    'USERSTORE_PASSWD': 'password',
    'USERSTORE_SSL': 'SIMPLE',
    'USERSTORE_PORT': '1389',
    'USERSTORE_SUFFIX': 'ou=identities',
    'acceptLicense': 'true',
    'LB_PRIMARY_URL': f'https://{AM_FQDN}:443/am',
    'LB_SITE_NAME': 'site1'
}


def config_thread():
    """
    Configuration thread.
    """
    url = f'http://openam:80/am/config/configurator'

    headers = {'Content-Type': 'application/x-www-form-urlencoded'}
    install_request = post(url=url, verify=False, headers=headers, params=properties)
    print(install_request.content)


def configure():
    """
    Do AM initial configuration. Configuration is executed in separate thread to allow main thread to
    read setup progress.
    """

    # Dump values used for configuration
    print(properties)

    # Start configure thread
    t = threading.Thread(target=config_thread)
    t.start()

    # Connect to progress. Read output.
    listener = get(url=f'http://openam:80/am/setup/setSetupProgress?mode=text',
                   verify=False, stream=True)
    if listener.encoding is None:
        listener.encoding = 'utf-8'

    # Configurator output
    for line in listener.iter_lines(decode_unicode=True):
        if line:
            print(line)


def wait_for_am():
    print("Waiting for AM and idrepo to boot up")
    ready = False
    while not ready:
        try:
            print("Trying endpoints.")
            am_request = get(url='http://openam:80/am/', timeout=10, verify=False)
            print(am_request.url)
            print( f'am_url, {am_request}')
            ds_request = get(url='http://ds-idrepo:8080/alive', timeout=10, verify=False)

            if 'options.htm' in am_request.url:
                print("AM ready to be configured")
                if ds_request.status_code is 200:
                    print("ID repo is ready as well")
                    return
                else:
                    print("DS not ready yet.")
            elif am_request.status_code == 200:
                print("AM is already installed! Exiting")
                sys.exit(0)
            else:
                print("AM not yet ready to be configured, waiting 10 seconds")
                time.sleep(10)
        except Exception:
            print("Not ready, sleep for 10 seconds...")
            time.sleep(10)
            # In case of different http exceptions we just pass and try again
            pass


if __name__ == '__main__':
    wait_for_am()
    configure()

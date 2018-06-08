"""
Product config class for tests. Parses env variables into classes and provides them to tests
Set env variables to override default ones before running tests

Also provides useful generated variables for products (rest endpoints url, etc...)

"""

import os


class AMConfig(object):
    def __init__(self):
        """

        """
        try:
            self.am_url = os.environ['AM_URL']
        except KeyError:
            self.am_url = 'http://openam.example.forgeops.com/openam'

        try:
            self.amadmin_pwd = os.environ['AM_ADMIN_PWD']
        except KeyError:
            self.amadmin_pwd = 'password'

        self.rest_authn_url = self.am_url + '/json/authenticate'
        self.rest_oauth2_authz_url = self.am_url + '/oauth2/authorize'


class IDMConfig(object):
    def __init__(self):
        try:
            self.idm_url = os.environ['IDM_URL']
        except KeyError:
            self.idm_url = 'http://openidm.example.forgeops.com/openidm'

        try:
            self.idm_admin_username = os.environ['IDM_ADMIN_USERNAME']
        except KeyError:
            self.idm_admin_username = 'openidm-admin'

        try:
            self.idm_admin_pwd = os.environ['IDM_ADMIN_PWD']
        except KeyError:
            self.idm_admin_pwd = 'openidm-admin'

        self.rest_ping_url = self.idm_url + '/info/ping'
        self.rest_managed_user_url = self.idm_url + '/managed/user'

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
        try:
            self.ig_url = os.environ['IG_URL']
        except KeyError:
            self.ig_url = 'http://openig.example.forgeops.com/'

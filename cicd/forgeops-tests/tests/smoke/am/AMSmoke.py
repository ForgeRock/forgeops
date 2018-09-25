"""
Basic OpenAM smoke test suite.
"""
import unittest
import re
from requests import get, post, delete

from config.ProductConfig import AMConfig


class AMSmoke(unittest.TestCase):
    amcfg = AMConfig()

    def test_0_setup(self):
        """Setup a user that will be tested in user login."""
        headers = {'X-OpenAM-Username': 'amadmin', 'X-OpenAM-Password': 'password',
                   'Content-Type': 'application/json', 'Accept-API-Version': 'resource=2.0, protocol=1.0'}
        resp = post(url=self.amcfg.rest_authn_url, headers=headers)
        self.assertEqual(200, resp.status_code, 'Admin login')
        admin_token = resp.json()["tokenId"]

        headers = {'iPlanetDirectoryPro': admin_token, 'Content-Type': 'application/json',
                   'Accept-API-Version': 'resource=3.0, protocol=2.1'}
        user_data = {'username': 'testuser',
                     'userpassword': 'password',
                     'mail': 'testuser@forgerock.com'}
        resp = post(self.amcfg.am_url + '/json/realms/root/users/?_action=create', headers=headers, json=user_data)
        self.assertEqual(201, resp.status_code, "Expecting test user to be created - HTTP-201")

    def test_1_ping(self):
        """Test if OpenAM is responding on isAlive endpoint"""
        resp = get(url=self.amcfg.am_url + '/isAlive.jsp')
        self.assertEqual(200, resp.status_code, "Ping OpenAM isAlive.jsp")

    def test_2_admin_login(self):
        """Test AuthN as amadmin"""
        headers = {'X-OpenAM-Username': 'amadmin', 'X-OpenAM-Password': 'password',
                   'Content-Type': 'application/json', 'Accept-API-Version': 'resource=2.0, protocol=1.0'}
        resp = post(url=self.amcfg.rest_authn_url, headers=headers)
        self.assertEqual(200, resp.status_code, 'Admin authn REST')

    def test_4_user_login(self):
        """Test AuthN as user"""
        headers = {'X-OpenAM-Username': 'testuser',
                   'X-OpenAM-Password': 'password',
                   'Content-Type': 'application/json',
                   'Accept-API-Version': 'resource=2.0, protocol=1.0'}
        resp = post(url=self.amcfg.rest_authn_url, headers=headers)
        self.assertEqual(200, resp.status_code, 'User authn REST')

    def test_5_oauth2_access_token(self):
        """Test Oauth2 access token"""

        headers = {'X-OpenAM-Username': 'testuser',
                   'X-OpenAM-Password': 'password',
                   'Content-Type': 'application/json',
                   'Accept-API-Version': 'resource=2.0, protocol=1.0'}

        resp = post(url=self.amcfg.rest_authn_url, headers=headers)
        self.assertEqual(200, resp.status_code, 'User authn REST')

        tokenid = resp.json()['tokenId']
        cookies = resp.cookies

        params = (('client_id', 'oauth2'),
                  ('scope', 'cn'),
                  ('state', '1234'),
                  ('redirect_uri', 'http://fake.com'),
                  ('response_type', 'code'),
                  ('realm', self.amcfg.am_realm))

        headers = {'Content-Type': 'application/x-www-form-urlencoded'}

        data = {"decision": "Allow", "csrf": tokenid}

        resp = post(url=self.amcfg.rest_oauth2_authz_url, data=data, headers=headers,
                    cookies=cookies, params=params, allow_redirects=False)
        self.assertEqual(302, resp.status_code, 'Oauth2 authz REST')

        location = resp.headers['Location']

        location_pattern = \
            '(http://|https://:.*).*(code=.*)&(scope=.*)&(iss=.*)&(state=.*)&(client_id=.*).*'

        prog = re.compile(location_pattern)
        result = prog.match(location)

        auth_code = result.group(2).split('=')[1]

        data = (('grant_type', 'authorization_code'),
                ('code', auth_code),
                ('redirect_uri', 'http://fake.com'))

        resp = post(url=self.amcfg.rest_oauth2_access_token_url, auth=('oauth2', 'password'),
                    data=data, headers=headers)
        self.assertEqual(200, resp.status_code, 'Oauth2 get access-token REST')

    def test_6_user_delete(self):
        """Test to delete user as amadmin"""
        headers = {'X-OpenAM-Username': 'amadmin', 'X-OpenAM-Password': 'password',
                   'Content-Type': 'application/json', 'Accept-API-Version': 'resource=2.0, protocol=1.0'}
        resp = post(url=self.amcfg.rest_authn_url, headers=headers)
        self.assertEqual(200, resp.status_code, 'Admin login')
        admin_token = resp.json()["tokenId"]

        headers = {'iPlanetDirectoryPro': admin_token, 'Content-Type': 'application/json',
                   'Accept-API-Version': 'resource=3.0, protocol=2.1'}

        resp = delete(self.amcfg.am_url + '/json/realms/root/users/testuser', headers=headers)
        self.assertEqual(200, resp.status_code, "Expecting test user to be deleted - HTTP-200")

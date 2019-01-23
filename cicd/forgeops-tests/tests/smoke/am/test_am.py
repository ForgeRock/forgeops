"""
Basic OpenAM smoke test suite.
"""
# Lib imports
import re
from requests import get, post, delete

# Framework imports
from ProductConfig import AMConfig
from utils import logger, rest


class TestAM(object):
    amcfg = AMConfig()

    @classmethod
    def setup_class(cls):
        """Setup a user that will be tested in user login."""

        headers = {'X-OpenAM-Username': 'amadmin', 'X-OpenAM-Password': 'password',
                   'Content-Type': 'application/json', 'Accept-API-Version': 'resource=2.0, protocol=1.0'}

        logger.test_step('Admin login')
        response = post(verify=cls.amcfg.ssl_verify, url=cls.amcfg.rest_authn_url, headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)

        admin_token = response.json()["tokenId"]

        headers = {'iPlanetDirectoryPro': admin_token, 'Content-Type': 'application/json',
                   'Accept-API-Version': 'resource=3.0, protocol=2.1'}
        user_data = {'username': 'testuser',
                     'userpassword': 'password',
                     'mail': 'testuser@forgerock.com'}

        logger.test_step('Expecting test user to be created - HTTP-201')
        response = post(verify=cls.amcfg.ssl_verify, url=cls.amcfg.am_url + '/json/realms/root/users/?_action=create',
                        headers=headers, json=user_data)
        rest.check_http_status(http_result=response, expected_status=201)

    def test_0_ping(self):
        """Test if OpenAM is responding on isAlive endpoint"""

        logger.test_step('Ping OpenAM isAlive.jsp')
        response = get(verify=self.amcfg.ssl_verify, url=self.amcfg.am_url + '/isAlive.jsp')
        rest.check_http_status(http_result=response, expected_status=200)

    def test_1_admin_login(self):
        """Test AuthN as amadmin"""

        headers = {'X-OpenAM-Username': 'amadmin', 'X-OpenAM-Password': 'password',
                   'Content-Type': 'application/json', 'Accept-API-Version': 'resource=2.0, protocol=1.0'}

        logger.test_step('Admin authn REST')
        response = post(verify=self.amcfg.ssl_verify, url=self.amcfg.rest_authn_url, headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)

    def test_2_user_login(self):
        """Test AuthN as user"""

        headers = {'X-OpenAM-Username': 'testuser',
                   'X-OpenAM-Password': 'password',
                   'Content-Type': 'application/json',
                   'Accept-API-Version': 'resource=2.0, protocol=1.0'}

        logger.test_step('User authn REST')
        response = post(verify=self.amcfg.ssl_verify, url=self.amcfg.rest_authn_url, headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)

    def test_3_oauth2_access_token(self):
        """Test Oauth2 access token"""

        headers = {'X-OpenAM-Username': 'testuser',
                   'X-OpenAM-Password': 'password',
                   'Content-Type': 'application/json',
                   'Accept-API-Version': 'resource=2.0, protocol=1.0'}

        logger.test_step('User authn REST')
        response = post(verify=self.amcfg.ssl_verify, url=self.amcfg.rest_authn_url, headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)

        tokenid = response.json()['tokenId']
        cookies = response.cookies

        params = (('client_id', 'oauth2'),
                  ('scope', 'cn'),
                  ('state', '1234'),
                  ('redirect_uri', 'http://fake.com'),
                  ('response_type', 'code'),
                  ('realm', self.amcfg.am_realm))

        headers = {'Content-Type': 'application/x-www-form-urlencoded'}

        data = {"decision": "Allow", "csrf": tokenid}

        logger.test_step('Oauth2 authz REST')
        response = post(verify=self.amcfg.ssl_verify, url=self.amcfg.rest_oauth2_authz_url, data=data, headers=headers,
                        cookies=cookies, params=params, allow_redirects=False)
        rest.check_http_status(http_result=response, expected_status=302)

        location = response.headers['Location']
        auth_code = re.findall('(?<=code=)(.+?)(?=&)', location)

        data = (('grant_type', 'authorization_code'),
                ('code', auth_code[0]),
                ('redirect_uri', 'http://fake.com'))

        logger.test_step('Oauth2 get access-token REST')
        response = post(verify=self.amcfg.ssl_verify, url=self.amcfg.rest_oauth2_access_token_url,
                        auth=('oauth2', 'password'), data=data, headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)

    @classmethod
    def teardown_class(cls):
        """Delete test user as amadmin"""

        headers = {'X-OpenAM-Username': 'amadmin', 'X-OpenAM-Password': 'password',
                   'Content-Type': 'application/json', 'Accept-API-Version': 'resource=2.0, protocol=1.0'}

        logger.test_step('Admin login')
        response = post(verify=cls.amcfg.ssl_verify, url=cls.amcfg.rest_authn_url, headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)

        admin_token = response.json()["tokenId"]

        headers = {'iPlanetDirectoryPro': admin_token, 'Content-Type': 'application/json',
                   'Accept-API-Version': 'resource=3.0, protocol=2.1'}

        logger.test_step('Expecting test user to be deleted - HTTP-200')
        response = delete(verify=cls.amcfg.ssl_verify, url=cls.amcfg.am_url + '/json/realms/root/users/testuser',
                          headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)

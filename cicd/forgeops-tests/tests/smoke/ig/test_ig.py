"""
Initial smoke tests for IG deployment
"""
# Lib imports
from requests import get, post, delete

# Framework imports
from ProductConfig import IGConfig, AMConfig
from utils import logger, rest


class TestIG(object):
    igcfg = IGConfig()
    amcfg = AMConfig()

    @classmethod
    def setup_class(cls):
        """Create user in AM to be used for testing"""

        headers = {'X-OpenAM-Username': 'amadmin', 'X-OpenAM-Password': 'password',
                   'Content-Type': 'application/json', 'Accept-API-Version': 'resource=2.0, protocol=1.0'}

        logger.test_step('Admin login')
        response = post(verify=cls.amcfg.ssl_verify, url=cls.amcfg.rest_authn_url, headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)

        admin_token = response.json()["tokenId"]

        headers = {'iPlanetDirectoryPro': admin_token, 'Content-Type': 'application/json',
                   'Accept-API-Version': 'resource=3.0, protocol=2.1'}
        user_data = {'username': 'igtestuser',
                     'userpassword': 'password',
                     'mail': 'testuser@forgerock.com'}

        logger.test_step('Expecting test user to be created - HTTP-201')
        response = post(verify=cls.amcfg.ssl_verify, url=cls.amcfg.am_url + '/json/realms/root/users/?_action=create',
                        headers=headers, json=user_data)
        rest.check_http_status(http_result=response, expected_status=201)

    def test_0_ping(self):
        """Test to check if we get to web page via IG reverse proxy"""

        logger.test_step('IG reverse proxy access')
        response = get(verify=self.igcfg.ssl_verify, url=self.igcfg.ig_url)
        rest.check_http_status(http_result=response, expected_status=200)

    def test_1_oauth2_tokeninfo(self):
        """Test to check oauth2 token from AM"""

        data = {
            'grant_type': 'password',
            'username': 'igtestuser',
            'password': 'password',
            'scope': 'mail employeenumber'
        }

        logger.test_step('Get access token')
        response = post(verify=self.amcfg.ssl_verify, url=self.amcfg.rest_oauth2_access_token_url,
                        auth=('oauth2', 'password'), data=data)
        rest.check_http_status(http_result=response, expected_status=200)

        access_token = response.json()['access_token']

        header = {'Authorization': 'Bearer ' + access_token}

        logger.test_step('Check if IG page contains access token and info')
        response = post(verify=self.igcfg.ssl_verify, url=self.igcfg.ig_url + '/rs-tokeninfo', headers=header)
        assert (str(response.content).__contains__('access_token=' + access_token) is True), \
            'IG page does not contain access token and info'

    def test_2_oauth2_tokenintrospect(self):
        """Test to check oauth2 token from AM"""

        data = {
            'grant_type': 'password',
            'username': 'igtestuser',
            'password': 'password',
            'scope': 'mail employeenumber'
        }

        logger.test_step('Get access token')
        response = post(verify=self.amcfg.ssl_verify, url=self.amcfg.rest_oauth2_access_token_url,
                        auth=('oauth2', 'password'), data=data)
        rest.check_http_status(http_result=response, expected_status=200)

        access_token = response.json()['access_token']

        header = {'Authorization': 'Bearer ' + access_token}

        logger.test_step('Get HTTP-200 on introspect endpoint')
        response = post(verify=self.igcfg.ssl_verify, url=self.igcfg.ig_url + '/rs-tokenintrospect', headers=header)
        rest.check_http_status(http_result=response, expected_status=200)

        logger.test_step('Expecting username on page')
        assert (str(response.content).__contains__('user_id=igtestuser') is True), 'User ID is not igtestuser'

        logger.test_step('Expecting client to be oauth2')
        assert (str(response.content).__contains__('client_id=oauth2') is True), 'Client ID is not oauth2'

    @classmethod
    def teardown_class(cls):
        """Remove user from AM"""

        headers = {'X-OpenAM-Username': 'amadmin', 'X-OpenAM-Password': 'password',
                   'Content-Type': 'application/json', 'Accept-API-Version': 'resource=2.0, protocol=1.0'}

        logger.test_step('Admin login')
        response = post(verify=cls.amcfg.ssl_verify, url=cls.amcfg.rest_authn_url, headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)

        admin_token = response.json()["tokenId"]

        headers = {'iPlanetDirectoryPro': admin_token, 'Content-Type': 'application/json',
                   'Accept-API-Version': 'resource=3.0, protocol=2.1'}

        logger.test_step('Expecting test user to be deleted - HTTP-200')
        response = delete(verify=cls.amcfg.ssl_verify, url=cls.amcfg.am_url + '/json/realms/root/users/igtestuser',
                          headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)

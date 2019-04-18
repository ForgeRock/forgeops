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

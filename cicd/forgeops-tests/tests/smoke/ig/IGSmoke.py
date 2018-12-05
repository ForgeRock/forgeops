"""
Initial smoke tests for IG deployment
"""
import unittest
from requests import get, post, delete
from requests.auth import HTTPBasicAuth

from config.ProductConfig import IGConfig, AMConfig


class IGSmoke(unittest.TestCase):
    igcfg = IGConfig()
    amcfg = AMConfig()

    def setUp(self):
        """Create user in AM to be used for testing"""
        headers = {'X-OpenAM-Username': 'amadmin', 'X-OpenAM-Password': 'password',
                   'Content-Type': 'application/json', 'Accept-API-Version': 'resource=2.0, protocol=1.0'}
        resp = post(verify=self.amcfg.ssl_verify, url=self.amcfg.rest_authn_url, headers=headers)
        self.assertEqual(200, resp.status_code, 'Admin login')
        admin_token = resp.json()["tokenId"]

        headers = {'iPlanetDirectoryPro': admin_token, 'Content-Type': 'application/json',
                   'Accept-API-Version': 'resource=3.0, protocol=2.1'}
        user_data = {'username': 'igtestuser',
                     'userpassword': 'password',
                     'mail': 'testuser@forgerock.com'}
        resp = post(verify=self.amcfg.ssl_verify, url=self.amcfg.am_url + '/json/realms/root/users/?_action=create',
                    headers=headers, json=user_data)
        self.assertEqual(201, resp.status_code, "Expecting test user to be created - HTTP-201")

    def test_reverse_proxy(self):
        """Test to check if we get to web page via IG reverse proxy"""
        resp = get(verify=self.igcfg.ssl_verify, url=self.igcfg.ig_url)
        self.assertEqual(200, resp.status_code, "IG reverse proxy access")

    def test_oauth2_tokeninfo(self):
        """Test to check oauth2 token from AM"""

        data = {
            'grant_type': 'password',
            'username': 'igtestuser',
            'password': 'password',
            'scope': 'mail employeenumber'
        }
        resp = post(verify=self.amcfg.ssl_verify, url=self.amcfg.rest_oauth2_access_token_url,
                    auth=('oauth2', 'password'), data=data)
        access_token = resp.json()['access_token']
        header = {'Authorization': 'Bearer ' + access_token}

        resp = post(verify=self.igcfg.ssl_verify, url=self.igcfg.ig_url + '/rs-tokeninfo', headers=header)
        self.assertTrue(str(resp.content).__contains__('access_token='+access_token),
                        'Check if IG page contains access token and info')

    def test_oauth2_tokenintrospect(self):
        """Test to check oauth2 token from AM"""

        data = {
            'grant_type': 'password',
            'username': 'igtestuser',
            'password': 'password',
            'scope': 'mail employeenumber'
        }
        resp = post(verify=self.amcfg.ssl_verify, url=self.amcfg.rest_oauth2_access_token_url,
                    auth=('oauth2', 'password'), data=data)
        access_token = resp.json()['access_token']

        header = {'Authorization': 'Bearer ' + access_token}

        resp = post(verify=self.igcfg.ssl_verify, url=self.igcfg.ig_url + '/rs-tokenintrospect', headers=header)
        self.assertEquals(resp.status_code, 200, 'Get HTTP-200 on introspect endpoint')
        self.assertTrue(str(resp.content).__contains__('user_id=igtestuser'), 'Expecting username on page')
        self.assertTrue(str(resp.content).__contains__('client_id=oauth2'), 'Expecting client to be oauth2')

    def tearDown(self):
        """Remove user from AM"""
        headers = {'X-OpenAM-Username': 'amadmin', 'X-OpenAM-Password': 'password',
                   'Content-Type': 'application/json', 'Accept-API-Version': 'resource=2.0, protocol=1.0'}
        resp = post(verify=self.amcfg.ssl_verify,  url=self.amcfg.rest_authn_url, headers=headers)
        self.assertEqual(200, resp.status_code, 'Admin login')
        admin_token = resp.json()["tokenId"]

        headers = {'iPlanetDirectoryPro': admin_token, 'Content-Type': 'application/json',
                   'Accept-API-Version': 'resource=3.0, protocol=2.1'}

        resp = delete(verify=self.amcfg.ssl_verify, url=self.amcfg.am_url + '/json/realms/root/users/igtestuser',
                      headers=headers)
        self.assertEqual(200, resp.status_code, "Expecting test user to be deleted - HTTP-200")

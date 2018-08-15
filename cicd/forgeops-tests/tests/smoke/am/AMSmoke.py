"""
Basic OpenAM smoke test suite.
"""
import unittest
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

    def test_5_user_delete(self):
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
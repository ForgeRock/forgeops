"""
Basic OpenAM smoke test suite.
"""
import unittest
from requests import get, post

from config.ProductConfig import AMConfig


class AMSmoke(unittest.TestCase):
    amcfg = AMConfig()

    def test_ping(self):
        resp = get(url=self.amcfg.am_url + '/isAlive.jsp')
        self.assertEqual(200, resp.status_code, "Ping OpenAM isAlive.jsp")

    def test_admin_login(self):
        headers = {'X-OpenAM-Username': 'amadmin', 'X-OpenAM-Password': 'password',
                   'Content-Type': 'application/json', 'Accept-API-Version': 'resource=2.0, protocol=1.0'}
        resp = post(url=self.amcfg.rest_authn_url, headers=headers)
        self.assertEqual(200, resp.status_code, 'Admin authn REST')

    def test_user_login(self):
        headers = {'X-OpenAM-Username': 'user.1',
                   'X-OpenAM-Password': 'password',
                   'Content-Type': 'application/json',
                   'Accept-API-Version': 'resource=2.0, protocol=1.0'}
        resp = post(url=self.amcfg.rest_authn_url, headers=headers)
        self.assertEqual(200, resp.status_code, 'User authn REST')
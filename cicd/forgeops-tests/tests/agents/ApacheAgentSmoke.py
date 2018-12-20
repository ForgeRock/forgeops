"""
Basic Apache agent smoke test suite
"""
import unittest
from lib.agent_utils import process_autosubmit_form
from requests import get, post, session

from config.ProductConfig import ApacheAgentConfig, AMConfig


class ApacheAgentSmoke(unittest.TestCase):
    agent_cfg = ApacheAgentConfig()
    amcfg = AMConfig()
    policy_url = '/policy.html'
    deny_policy_url = '/deny.html'
    neu_url = '/neu.html'

    def test_0_create_test_user(self):
        """Setup a user that will be tested in user login."""

        headers = {'X-OpenAM-Username': 'amadmin', 'X-OpenAM-Password': 'password',
                   'Content-Type': 'application/json', 'Accept-API-Version': 'resource=2.0, protocol=1.0'}
        resp = post(verify=self.amcfg.ssl_verify, url=self.amcfg.rest_authn_url, headers=headers)
        self.assertEqual(200, resp.status_code, 'Admin login')
        admin_token = resp.json()["tokenId"]

        headers = {'iPlanetDirectoryPro': admin_token, 'Content-Type': 'application/json',
                   'Accept-API-Version': 'resource=3.0, protocol=2.1'}
        user_data = {'username': 'testuser-apache',
                     'userpassword': 'password',
                     'mail': 'testuser-nginx@forgerock.com'}
        resp = post(verify=self.amcfg.ssl_verify, url=self.amcfg.am_url + '/json/realms/root/users/?_action=create', headers=headers, json=user_data)
        self.assertEqual(201, resp.status_code, "Expecting test user to be created - HTTP-201")

    def test_redirect(self):
        """Test if agent redirects to AM"""
        resp = get(verify=self.amcfg.ssl_verify, url=self.agent_cfg.agent_url, allow_redirects=False)
        self.assertEqual(302, resp.status_code, 'Expecting 302 redirect to AM login')
        self.assertTrue('openam' in resp.headers.get('location'), 'Expecting openam to be in location header')

    def test_access_allowed_resource(self):
        """Test if we can access resource - allowed by policy"""
        s = session()
        s.headers = {'X-OpenAM-Username': 'testuser-apache', 'X-OpenAM-Password': 'password',
                     'Content-Type': 'application/json', 'Accept-API-Version': 'resource=2.0, protocol=1.0'}
        resp = s.post(verify=self.amcfg.ssl_verify, url=self.amcfg.rest_authn_url, headers=s.headers)
        self.assertEqual(200, resp.status_code, 'User needs to login')

        resp = s.get(verify=self.amcfg.ssl_verify, url=self.agent_cfg.agent_url + self.policy_url)
        self.assertEqual(200, resp.status_code, 'Expecting HTTP-200 from autosubmit page')

        r = process_autosubmit_form(resp, s)
        self.assertTrue('Policy testing page' in r.text, "Expecting Policy testing page string")
        self.assertEqual(200, r.status_code, "Expecting HTTP-200 in response")

        s.close()

    def test_access_denied_resource(self):
        """Test that we can't access resource - denied by policy"""
        s = session()
        s.headers = {'X-OpenAM-Username': 'testuser-apache', 'X-OpenAM-Password': 'password',
                     'Content-Type': 'application/json', 'Accept-API-Version': 'resource=2.0, protocol=1.0'}
        resp = s.post(verify=self.amcfg.ssl_verify, url=self.amcfg.rest_authn_url, headers=s.headers)
        self.assertEqual(200, resp.status_code, 'User login, expecting HTTP-200')

        resp = s.get(verify=self.amcfg.ssl_verify, url=self.agent_cfg.agent_url + self.deny_policy_url)
        r = process_autosubmit_form(resp, s)
        self.assertEqual(403, r.status_code, 'Expecting HTTP-403 when accessing allowed resource')

        s.close()

    def test_access_neu_url(self):
        """Test if we can access resource without login - allowed by not enforced url"""
        resp = get(verify=self.amcfg.ssl_verify, url=self.agent_cfg.agent_url + self.neu_url)
        self.assertEqual(200, resp.status_code, "Expecting to have access to NEU url")

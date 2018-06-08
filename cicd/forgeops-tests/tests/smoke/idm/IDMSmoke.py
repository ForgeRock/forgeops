"""
Basic smoke test for IDM.

Test is based on bidirectional sync with ldap configuration.

Contains CRUD on user operations + running replication.

Test are sorted automatically so that's why it's needed to keep test_0[1,2,3]_ naming.
"""
# Lib imports
import unittest
from requests import get, post, put, delete

# Framework imports
from config.ProductConfig import IDMConfig


class IDMSmoke(unittest.TestCase):
    idmcfg = IDMConfig()
    testuser = '/forgeops-testuser'

    def test_0_ping(self):
        resp = get(auth=('openidm-admin', 'openidm-admin'), url=self.idmcfg.rest_ping_url)
        self.assertEqual(resp.status_code, 200)

    def test_1_create_managed_user(self):
        headers = self.idmcfg.get_admin_headers({
            'Content-Type': 'application/json',
            'if-none-match': '*'
        })

        payload = """{"userName": "forgeops-testuser",
                   "telephoneNumber": "6669876987",
                   "givenName": "devopsguy",
                   "description": "Just another user",
                   "sn": "sutter",
                   "mail": "rick@example.com",
                   "password": "Th3Password",
                   "accountStatus": "active" } """

        resp = put(url=self.idmcfg.rest_managed_user_url + self.testuser, headers=headers, data=payload)
        self.assertEqual(201, resp.status_code, 'Create test user')

    def test_2_update_managed_user(self):
        headers = self.idmcfg.get_admin_headers({
            'Content-Type': 'application/json',
            'if-match': '*'})
        payload = """{"userName": "forgeops-testuser",
                   "telephoneNumber": "6669876987",
                   "givenName": "devopsguy",
                   "description": "Just another user",
                   "sn": "sutter",
                   "mail": "rick@example.com",
                   "password": "Th3RealPassword",
                   "accountStatus": "active"} """

        resp = put(url=self.idmcfg.rest_managed_user_url + self.testuser, headers=headers, data=payload)
        self.assertEqual(200, resp.status_code, 'Update test user')

    def test_3_run_recon_to_ldap(self):
        headers = self.idmcfg.get_admin_headers({
            'Content-Type': 'application/json'
        })

        params = {
            '_action': 'recon',
            'mapping': 'managedUser_systemLdapAccounts',
            'waitForCompletion': 'True'
        }

        resp = post(url=self.idmcfg.idm_url + '/recon', params=params, headers=headers)
        self.assertEqual(200, resp.status_code, "Reconciliation")

    def test_4_login_managed_user(self):
        headers = {'X-OpenIDM-Username': 'forgeops-testuser',
                   'X-OpenIDM-Password': 'Th3RealPassword',
                   'Content-Type': 'application/json',
                   }
        resp = get(url=self.idmcfg.rest_ping_url, headers=headers)
        self.assertEqual(200, resp.status_code, "Login managed user and access ping endpoint")

    def test_5_delete_managed_user(self):
        headers = self.idmcfg.get_admin_headers({
            'Content-Type': 'application/json',
            'if-match': '*',
        })
        resp = delete(url=self.idmcfg.rest_managed_user_url + self.testuser, headers=headers)
        self.assertEqual(200, resp.status_code, "Delete test user")

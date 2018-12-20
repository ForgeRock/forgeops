"""
Basic smoke test for IDM.

Test is based on bidirectional sync with ldap configuration.

Contains CRUD on user operations + running replication.

Test are sorted automatically so that's why it's needed to keep test_0[1,2,3]_ naming.
"""
# Lib imports
import json

import unittest
from requests import get, post, put, delete, session

# Framework imports
from config.ProductConfig import IDMConfig


class IDMSmoke(unittest.TestCase):
    idmcfg = IDMConfig()
    testuser = '/forgeops-testuser'

    def test_0_ping(self):
        """Pings OpenIDM to see if server is alive using admin headers"""
        resp = get(verify=self.idmcfg.ssl_verify, auth=('openidm-admin', 'openidm-admin'),
                   url=self.idmcfg.rest_ping_url)
        self.assertEqual(resp.status_code, 200)

    def test_1_create_managed_user(self):
        """Test to create managed user as admin"""
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

        resp = put(verify=self.idmcfg.ssl_verify, url=self.idmcfg.rest_managed_user_url + self.testuser,
                   headers=headers, data=payload)
        self.assertEqual(201, resp.status_code, 'Create test user')

    def test_2_update_managed_user(self):
        """Test to update managed user as admin"""
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

        resp = put(verify=self.idmcfg.ssl_verify, url=self.idmcfg.rest_managed_user_url + self.testuser,
                   headers=headers, data=payload)
        self.assertEqual(200, resp.status_code, 'Update test user - ' + str(resp.text))

    def test_3_run_recon_to_ldap(self):
        """Test to run reconciliation to ldap"""
        headers = self.idmcfg.get_admin_headers({
            'Content-Type': 'application/json'
        })

        params = {
            '_action': 'recon',
            'mapping': 'managedUser_systemLdapAccounts',
            'waitForCompletion': 'True'
        }

        resp = post(verify=self.idmcfg.ssl_verify, url=self.idmcfg.idm_url + '/recon', params=params, headers=headers)
        self.assertEqual(200, resp.status_code, "Reconciliation")

    def test_4_login_managed_user(self):
        """Test login as managed user"""
        headers = {'X-OpenIDM-Username': 'forgeops-testuser',
                   'X-OpenIDM-Password': 'Th3RealPassword',
                   'Content-Type': 'application/json',
                   }
        resp = get(verify=self.idmcfg.ssl_verify, url=self.idmcfg.rest_ping_url, headers=headers)
        self.assertEqual(200, resp.status_code, "Login managed user and access ping endpoint")

    def test_5_delete_managed_user(self):
        """Test to delete managed user as admin"""
        headers = self.idmcfg.get_admin_headers({
            'Content-Type': 'application/json',
            'if-match': '*',
        })
        resp = delete(verify=self.idmcfg.ssl_verify, url=self.idmcfg.rest_managed_user_url + self.testuser,
                      headers=headers)
        self.assertEqual(200, resp.status_code, "Delete test user")

    def test_6_user_self_registration(self):
        """Test to use self service registration as user"""
        user_data = {
            "input": {
                "user": {
                    "userName": "rsutter",
                    "givenName": "rick",
                    "sn": "sutter",
                    "mail": "rick@mail.com",
                    "password": "Welcome1",
                    "preferences": {
                        "updates": False,
                        "marketing": False
                    }
                },
                "kba": [
                    {
                        "answer": "black",
                        "questionId": "1"
                    }
                ]
            }
        }

        headers = {'Content-Type': 'application/json',
                   'X-OpenIDM-Username': 'anonymous',
                   'X-OpenIDM-Password': 'anonymous',
                   'Cache-Control': 'no-cache'}
        params = {'_action': 'submitRequirements'}
        resp = post(verify=self.idmcfg.ssl_verify, url=self.idmcfg.rest_selfreg_url, params=params,
                    headers=headers, json=user_data)
        token = resp.json()["token"]
        user_data["token"] = token
        resp = post(verify=self.idmcfg.ssl_verify, url=self.idmcfg.rest_selfreg_url, params=params,
                    headers=headers, json=user_data)

        self.assertEqual(200, resp.status_code)
        self.assertTrue(resp.json()['status']['success'], "Expecting success in returned json")

    def test_7_user_reset_pw(self):
        """Test to use self service password reset as user"""
        s = session()
        headers_init = {
            'Content-Type': 'application/json',
            'X-OpenIDM-Username': 'anonymous',
            'X-OpenIDM-Password': 'anonymous',
            'Cache-Control': 'no-cache',
            'X-OpenIDM-NoSession': "true",
            "Accept-API-Version": "protocol=1.0,resource=1.0"
        }

        headers = {
            'Content-Type': 'application/json',
            'X-OpenIDM-Username': 'anonymous',
            'X-OpenIDM-Password': 'anonymous',
            'Cache-Control': 'no-cache'
        }

        params = {
            '_action': 'submitRequirements'
        }

        payload1 = {
            "input": {
                'queryFilter': 'userName eq \"rsutter\"'
            }
        }

        stage1 = s.post(verify=self.idmcfg.ssl_verify, url=self.idmcfg.rest_selfpwreset_url, headers=headers_init,
                        params=params, json=payload1)
        self.assertEqual(200, stage1.status_code, "Try to find user with query for pw reset")

        payload2 = {
            "token": stage1.json()["token"],
            "input": {
                'queryFilter': 'userName eq \"rsutter\"'
            }
        }
        stage2 = s.post(verify=self.idmcfg.ssl_verify, url=self.idmcfg.rest_selfpwreset_url, headers=headers_init,
                        params=params, json=payload2)
        self.assertEqual(200, stage2.status_code, "Stage 2 - Query user")

        payload3 = {
            "token": stage2.json()["token"],
            "input": {
                "answer1": "black"
            }
        }

        stage3 = s.post(verify=self.idmcfg.ssl_verify, url=self.idmcfg.rest_selfpwreset_url, headers=headers,
                        params=params, json=payload3)
        self.assertEqual(200, stage3.status_code, "Stage 3 - Answer question")

        payload4 = {
            "token": stage3.json()["token"],
            "input": {
                "password": "Th3Password"
            }
        }

        stage4 = s.post(verify=self.idmcfg.ssl_verify, url=self.idmcfg.rest_selfpwreset_url, headers=headers,
                        params=params, json=payload4)
        self.assertEqual(200, stage4.status_code, "Stage 4 - Password reset")
        s.close()

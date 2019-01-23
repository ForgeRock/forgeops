"""
Basic smoke test for IDM.

Test is based on bidirectional sync with ldap configuration.

Contains CRUD on user operations + running replication.

Test are sorted automatically so that's why it's needed to keep test_0[1,2,3]_ naming.
"""
# Lib imports
from requests import get, post, put, delete, session

# Framework imports
from ProductConfig import IDMConfig
from utils import logger, rest


class TestIDM(object):
    idmcfg = IDMConfig()
    testuser = '/forgeops-testuser'

    def test_0_ping(self):
        """Pings OpenIDM to see if server is alive using admin headers"""

        logger.test_step('Ping OpenIDM')
        response = get(verify=self.idmcfg.ssl_verify, auth=('openidm-admin', 'openidm-admin'),
                       url=self.idmcfg.rest_ping_url)
        rest.check_http_status(http_result=response, expected_status=200)

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

        logger.test_step('Create test user')
        response = put(verify=self.idmcfg.ssl_verify, url=self.idmcfg.rest_managed_user_url + self.testuser,
                       headers=headers, data=payload)
        rest.check_http_status(http_result=response, expected_status=201)

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

        logger.test_step('Update test user')
        response = put(verify=self.idmcfg.ssl_verify, url=self.idmcfg.rest_managed_user_url + self.testuser,
                       headers=headers, data=payload)
        rest.check_http_status(http_result=response, expected_status=200)

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

        logger.test_step('Reconciliation')
        response = post(verify=self.idmcfg.ssl_verify, url=self.idmcfg.idm_url + '/recon', params=params,
                        headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)

    def test_4_login_managed_user(self):
        """Test login as managed user"""

        headers = {'X-OpenIDM-Username': 'forgeops-testuser',
                   'X-OpenIDM-Password': 'Th3RealPassword',
                   'Content-Type': 'application/json',
                   }

        logger.test_step('Login managed user and access ping endpoint')
        response = get(verify=self.idmcfg.ssl_verify, url=self.idmcfg.rest_ping_url, headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)

    def test_5_delete_managed_user(self):
        """Test to delete managed user as admin"""

        headers = self.idmcfg.get_admin_headers({
            'Content-Type': 'application/json',
            'if-match': '*',
        })

        logger.test_step('Delete test user')
        response = delete(verify=self.idmcfg.ssl_verify, url=self.idmcfg.rest_managed_user_url + self.testuser,
                          headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)

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

        logger.test_step('Get token')
        response = post(verify=self.idmcfg.ssl_verify, url=self.idmcfg.rest_selfreg_url, params=params,
                        headers=headers, json=user_data)
        rest.check_http_status(http_result=response, expected_status=200)

        token = response.json()["token"]
        user_data["token"] = token

        logger.test_step('Self register as user')
        response = post(verify=self.idmcfg.ssl_verify, url=self.idmcfg.rest_selfreg_url, params=params,
                        headers=headers, json=user_data)
        rest.check_http_status(http_result=response, expected_status=200)

        logger.test_step('Expecting success in returned json"')
        assert (response.json()['status']['success'] is True), "Response's status is not True"

    def test_7_user_reset_pw(self):
        """Test to use self service password reset as user"""

        current_session = session()

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

        logger.test_step('Stage 1 - Try to find user with query for pw reset')
        response_stage1 = current_session.post(verify=self.idmcfg.ssl_verify, url=self.idmcfg.rest_selfpwreset_url,
                                               headers=headers_init, params=params, json=payload1)
        rest.check_http_status(http_result=response_stage1, expected_status=200)

        payload2 = {
            "token": response_stage1.json()["token"],
            "input": {
                'queryFilter': 'userName eq \"rsutter\"'
            }
        }

        logger.test_step('Stage 2 - Query user')
        response_stage2 = current_session.post(verify=self.idmcfg.ssl_verify, url=self.idmcfg.rest_selfpwreset_url,
                                               headers=headers_init, params=params, json=payload2)
        rest.check_http_status(http_result=response_stage2, expected_status=200)

        payload3 = {
            "token": response_stage2.json()["token"],
            "input": {
                "answer1": "black"
            }
        }

        logger.test_step('Stage 3 - Answer question')
        response_stage3 = current_session.post(verify=self.idmcfg.ssl_verify, url=self.idmcfg.rest_selfpwreset_url,
                                               headers=headers, params=params, json=payload3)
        rest.check_http_status(http_result=response_stage3, expected_status=200)

        payload4 = {
            "token": response_stage3.json()["token"],
            "input": {
                "password": "Th3Password"
            }
        }

        logger.test_step('Stage 4 - Password reset')
        response_stage4 = current_session.post(verify=self.idmcfg.ssl_verify, url=self.idmcfg.rest_selfpwreset_url,
                                               headers=headers, params=params, json=payload4)
        rest.check_http_status(http_result=response_stage4, expected_status=200)

        current_session.close()

    @classmethod
    def teardown_class(cls):
        """Delete user rsutter"""

        headers1 = cls.idmcfg.get_admin_headers({
            'Content-Type': 'application/json'
        })

        logger.test_step('Get user id')
        response = get(verify=cls.idmcfg.ssl_verify, url=cls.idmcfg.rest_managed_user_url + '?_queryFilter=true',
                       headers=headers1).json()
        #rest.check_http_status(http_result=response, expected_status=200)

        _id = response["result"][0]["_id"]

        headers2 = cls.idmcfg.get_admin_headers({
            'Content-Type': 'application/json',
            'if-match': '*',
        })

        logger.test_step('Delete user')
        response = delete(verify=cls.idmcfg.ssl_verify, url=cls.idmcfg.rest_managed_user_url + '/' + _id,
                          headers=headers2)
        rest.check_http_status(http_result=response, expected_status=200)

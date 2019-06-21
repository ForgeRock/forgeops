"""
Basic smoke test for IDM.
Test are sorted automatically so that's why it's needed to keep test_0[1,2,3]_ naming.
"""

# Lib imports
from requests import get, post, put, delete, session, patch

# Framework imports
from ProductConfig import IDMConfig
from utils import logger, rest

class TestIDM(object):
    idmcfg = IDMConfig()
    testuser = 'forgeops-testuser'

    def test_0_ping(self):
        """Simple ping test to IDM"""

        logger.test_step('Ping OpenIDM')
        response = get(verify=self.idmcfg.ssl_verify, url=self.idmcfg.rest_ping_url,
                       headers=self.idmcfg.get_admin_headers(None))
        rest.check_http_status(http_result=response, expected_status=200)

    def test_1_create_managed_user(self):
        """Test to create managed user as admin"""

        payload = """{"userName": "forgeops-testuser",
                   "telephoneNumber": "6669876987",
                   "givenName": "devopsguy",
                   "description": "Just another user",
                   "sn": "sutter",
                   "mail": "rick@example.com",
                   "password": "Th3Password",
                   "accountStatus": "active" } """

        logger.test_step('Create test user')
        self.idmcfg.create_user(payload)

    def test_2_update_managed_user(self):
        """Test to update managed user as admin"""
        headers = self.idmcfg.get_admin_headers({'Content-Type': 'application/json',
                                                 'If-Match': '*'})

        user_id = self.idmcfg.get_userid_by_name(self.testuser)
        payload = """[{"operation":"replace", "field":"/telephoneNumber", "value":"15031234567"}]"""

        logger.test_step('Update test user')
        response = patch(verify=self.idmcfg.ssl_verify, url=f'{self.idmcfg.rest_managed_user_url}/{user_id}',
                        headers=headers, data=payload)
        rest.check_http_status(response, expected_status=200)

    def test_3_delete_managed_user(self):
        """Test to delete managed user as admin"""
        user_id = self.idmcfg.get_userid_by_name(self.testuser)
        self.idmcfg.delete_user(user_id)

    @classmethod
    def teardown_class(cls):
        """"""

        headers1 = cls.idmcfg.get_admin_headers({
            'Content-Type': 'application/json'
        })

        logger.test_step('Get user id')
        response = get(verify=cls.idmcfg.ssl_verify, url=cls.idmcfg.rest_managed_user_url + '?_queryFilter=true',
                       headers=headers1).json()
        # rest.check_http_status(http_result=response, expected_status=200)
        if response['resultCount'] == 0:
            return
        _id = response["result"][0]["_id"]

        headers2 = cls.idmcfg.get_admin_headers({
            'Content-Type': 'application/json',
            'if-match': '*',
        })

        logger.test_step('Delete user')
        response = delete(verify=cls.idmcfg.ssl_verify, url=cls.idmcfg.rest_managed_user_url + '/' + _id,
                          headers=headers2)
        rest.check_http_status(http_result=response, expected_status=200)

    # Helper methods


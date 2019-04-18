"""
Couple of basic integration tests between AM and IDM using shared id_repo
"""
import json

from ProductConfig import AMConfig, IDMConfig
from utils import logger, rest
from requests import get

class TestIntegration(object):
    amcfg = AMConfig()
    idmcfg = IDMConfig()

    def test_1_idm_create_user_am_login_user(self):
        """
        Creates a user in IDM and tries to login with user with AM
        """
        username = 'idm_user'
        password = 'Th3Password'

        user_payload = json.dumps({
           'userName': username,
           'telephoneNumber': '6669876987',
           'givenName': 'CreatedInIdm',
           'description': 'Just another user',
           'sn': 'idmcreateduser',
           'mail': 'my-mail@liam.com',
           'password': password,
           'accountStatus': 'active'
        })
                
        logger.test_step('Creating user in IDM')
        self.idmcfg.create_user(user_payload)
        logger.test_step('Trying to login created user to AM')
        self.amcfg.login_user(username, password)
        logger.test_step('Deleting user with AM')
        self.amcfg.delete_user(username)

    def test_2_am_create_user_idm_query_user(self):
        username = 'am_user'
        password = 'GreatP4ssword'

        logger.test_step('Creating user in AM')
        self.amcfg.create_user(username, password)
        logger.test_step('Querying user in IDM')
        userid = self.idmcfg.get_userid_by_name(username)
        request = get(url=f'{self.idmcfg.rest_managed_user_url}/{userid}',
                      headers=self.idmcfg.get_admin_headers(),
                      verify=self.idmcfg.ssl_verify)
        rest.check_http_status(request, 200)
        assert f'{username}@forgerock.com' in request.json()['mail']

    @classmethod
    def teardown_class(cls):
        """
        Deletes all created users
        """
        headers1 = cls.idmcfg.get_admin_headers({
            'Content-Type': 'application/json'
        })

        logger.test_step('Get user id')
        response = get(verify=cls.idmcfg.ssl_verify, url=cls.idmcfg.rest_managed_user_url + '?_queryFilter=true',
                       headers=headers1).json()
        # rest.check_http_status(http_result=response, expected_status=200)
        if response['resultCount'] == 0:
            return

        for result in response['result']:
            _id = result['_id']
            print(f'ID>>>>>>>>>>>>>>>>>>>>>{_id}')
            logger.test_step('Delete user')
            cls.idmcfg.delete_user(_id)

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
 

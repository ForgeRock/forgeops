"""
Experimental UI tests
"""
import json
import time

from ProductConfig import IDMConfig, EndUserUIConfig
from selenium import webdriver


class TestUI(object):
    idmcfg = IDMConfig()
    uiconfig = EndUserUIConfig()
    username = 'uiuser'
    password = 'Passw0rd'
    driver = None

    @classmethod
    def setup_class(cls):
        """Setup webdriver and a user that will be tested in user login."""

        options = webdriver.ChromeOptions()
        options.headless = True
        options.add_argument('--ignore-certificate-errors')

        # Needed for docker
        options.add_argument('--no-sandbox')
        options.add_argument('--disable-gpu')
        
        cls.driver = webdriver.Chrome(options=options,
                                      executable_path='/usr/bin/chromedriver')

        user_payload = json.dumps({
            'userName': cls.username,
            'telephoneNumber': '6669876987',
            'givenName': 'CreatedInIdm',
            'description': 'Just another user',
            'sn': 'idmcreateduser',
            'mail': 'my-mail@liam.com',
            'password': cls.password,
            'accountStatus': 'active'
        })

        cls.idmcfg.create_user(payload=user_payload)

    def test_1_ui_login(self):
        """Test to access end UI and do login flow"""

        self.driver.get(self.uiconfig.ui_url)
        time.sleep(10)
        # We expect to see AM landing page
        assert self.driver.title == 'ForgeRock Access Management'
        self.driver.find_element_by_id('idToken1').send_keys(self.username)
        self.driver.find_element_by_id('idToken2').send_keys(self.password)
        self.driver.find_element_by_id('loginButton_0').click()

        # We expect to land in IDM UI after successful login
        # and have iPDP cookie in cookie list
        time.sleep(10)
        assert self.driver.title == 'Identity Management'
        assert self.driver.get_cookie('iPlanetDirectoryPro') is not None

    @classmethod
    def teardown_class(cls):
        cls.idmcfg.delete_user(cls.idmcfg.get_userid_by_name(cls.username))

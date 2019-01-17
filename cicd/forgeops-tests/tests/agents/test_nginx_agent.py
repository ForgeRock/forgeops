"""
Basic Apache agent smoke test suite
"""
# Lib imports
from requests import get, post, session

# Framework imports
from ProductConfig import NginxAgentConfig, AMConfig
from agent_utils import process_autosubmit_form
from utils import logger, rest


class TestNginxAgent(object):
    agent_cfg = NginxAgentConfig()
    amcfg = AMConfig()
    policy_url = '/policy.html'
    deny_policy_url = '/deny.html'
    neu_url = '/neu.html'

    def test_0_create_test_user(self):
        """Setup a user that will be tested in user login."""

        headers = {'X-OpenAM-Username': 'amadmin', 'X-OpenAM-Password': 'password',
                   'Content-Type': 'application/json', 'Accept-API-Version': 'resource=2.0, protocol=1.0'}

        logger.test_step('Admin login')
        response = post(verify=self.amcfg.ssl_verify, url=self.amcfg.rest_authn_url, headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)

        admin_token = response.json()["tokenId"]

        headers = {'iPlanetDirectoryPro': admin_token, 'Content-Type': 'application/json',
                   'Accept-API-Version': 'resource=3.0, protocol=2.1'}
        user_data = {'username': 'testuser-nginx',
                     'userpassword': 'password',
                     'mail': 'testuser-nginx@forgerock.com'}

        logger.test_step('Expecting test user to be created - HTTP-201')
        response = post(verify=self.amcfg.ssl_verify, url=self.amcfg.am_url + '/json/realms/root/users/?_action=create',
                        headers=headers, json=user_data)
        rest.check_http_status(http_result=response, expected_status=201)

    def test_redirect(self):
        """Test if agent redirects to AM"""

        logger.test_step('Expecting 302 redirect to AM login')
        response = get(verify=self.amcfg.ssl_verify, url=self.agent_cfg.agent_url, allow_redirects=False)
        rest.check_http_status(http_result=response, expected_status=302)

        logger.test_step('Expecting openam to be in location header')
        assert ('openam' in response.headers.get('location') is True), 'openam not found in location header'

    def test_access_allowed_resource(self):
        """Test if we can access resource - allowed by policy"""

        current_session = session()

        current_session.headers = {'X-OpenAM-Username': 'testuser-nginx', 'X-OpenAM-Password': 'password',
                                   'Content-Type': 'application/json',
                                   'Accept-API-Version': 'resource=2.0, protocol=1.0'}

        logger.test_step('User needs to login')
        response = current_session.post(verify=self.amcfg.ssl_verify, url=self.amcfg.rest_authn_url,
                                        headers=current_session.headers)
        rest.check_http_status(http_result=response, expected_status=200)

        logger.test_step('Expecting HTTP-200 from autosubmit page')
        response = current_session.get(verify=self.amcfg.ssl_verify, url=self.agent_cfg.agent_url + self.policy_url)
        rest.check_http_status(http_result=response, expected_status=200)

        logger.test_step('Expecting HTTP-200 in response')
        response = process_autosubmit_form(response, current_session)
        rest.check_http_status(http_result=response, expected_status=200)

        logger.test_step('Expecting Policy testing page string')
        assert ('Policy testing page' in response.text is True), 'Policy testing page string not found in response'

        current_session.close()

    def test_access_denied_resource(self):
        """Test that we can't access resource - denied by policy"""

        current_session = session()

        current_session.headers = {'X-OpenAM-Username': 'testuser-nginx', 'X-OpenAM-Password': 'password',
                                   'Content-Type': 'application/json',
                                   'Accept-API-Version': 'resource=2.0, protocol=1.0'}

        logger.test_step('User login, expecting HTTP-200')
        response = current_session.post(verify=self.amcfg.ssl_verify, url=self.amcfg.rest_authn_url,
                                        headers=current_session.headers)
        rest.check_http_status(http_result=response, expected_status=200)

        logger.test_step('Expecting HTTP-403 when accessing allowed resource')
        response = current_session.get(verify=self.amcfg.ssl_verify,
                                       url=self.agent_cfg.agent_url + self.deny_policy_url)
        response = process_autosubmit_form(response, current_session)
        rest.check_http_status(http_result=response, expected_status=403)

        current_session.close()

    def test_access_neu_url(self):
        """Test if we can access resource without login - allowed by not enforced url"""

        logger.test_step('Expecting to have access to NEU url')
        response = get(verify=self.amcfg.ssl_verify, url=self.agent_cfg.agent_url + self.neu_url)
        rest.check_http_status(http_result=response, expected_status=200)

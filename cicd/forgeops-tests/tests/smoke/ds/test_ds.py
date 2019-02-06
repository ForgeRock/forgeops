"""
Basic smoke test for DS.

Test is based on bidirectional sync with ldap configuration.

Contains CRUD on user operations + running replication.

Test are sorted automatically so that's why it's needed to keep test_0[1,2,3]_ naming.
"""
# Lib imports
import pytest
from requests import get, put, delete

# Framework imports
from ProductConfig import DSConfig
from utils import logger, rest


class TestDS(object):
    dscfg = DSConfig()

    @classmethod
    def setup_class(cls):
        """Start port-forward if needed"""

        cls.dscfg.ds0_popen = cls.dscfg.start_ds_port_forward(instance_nb=0)
        cls.dscfg.ds1_popen = cls.dscfg.start_ds_port_forward(instance_nb=1)

    def test_0_ping(self):
        """Pings OpenDJ instances to see if servers are alive"""

        logger.test_step('Check userstore-0 is alive')
        response = get(verify=self.dscfg.ssl_verify, url=self.dscfg.ds0_rest_ping_url)
        rest.check_http_status(http_result=response, expected_status=200)

        logger.test_step('Check userstore-1 is alive')
        response = get(verify=self.dscfg.ssl_verify, url=self.dscfg.ds1_rest_ping_url)
        rest.check_http_status(http_result=response, expected_status=200)

    def test_1_resource_replication(self, setup_teardown_test_resource_replication):
        """Creates a new resource via rest2ldap interface and
           verifies it is replicated to the second instance.
           Ref:  https://ea.forgerock.com/docs/ds/rest-guide/create-rest.html#create-rest"""

        headers = {'Content-Type': 'application/json',
                   'If-None-Match': '*'
                   }

        json_data = {
            "_id": "newuser_ds0",
            "displayName": ["newuser_added_to_ds0"],
            "contactInformation": {
                "telephoneNumber": "+1 408 555 1212",
                "emailAddress": "newuser_ds0@example.com"
            },
            "name": {
                "familyName": "New",
                "givenName": "UserDSZero"
            },
            "_schema": "frapi:opendj:rest2ldap:user:1.0"
        }

        logger.test_step('Creating a new user entry with ID newuser_ds0')
        response = put(verify=self.dscfg.ssl_verify, url=self.dscfg.ds0_url + '/api/users/newuser_ds0',
                       auth=('am-identity-bind-account', 'password'), headers=headers, json=json_data)
        rest.check_http_status(http_result=response, expected_status=201)

        logger.test_step('Verifying user entry with ID newuser_ds0 replicated in userstore-1')
        response = get(verify=self.dscfg.ssl_verify, url=self.dscfg.ds1_url + '/api/users/newuser_ds0',
                       auth=('am-identity-bind-account', 'password'))
        rest.check_http_status(http_result=response, expected_status=200)

    @pytest.fixture()
    def setup_teardown_test_resource_replication(self):
        """"Setup and Teardown for test_resource_replication"""

        yield "resource"
        logger.test_step('Deleting user entry with ID newuser_ds0 from userstore-0')
        response = delete(verify=self.dscfg.ssl_verify, url=self.dscfg.ds0_url + '/api/users/newuser_ds0',
                          auth=('am-identity-bind-account', 'password'))
        rest.check_http_status(http_result=response, expected_status=200)

        logger.test_step('Verifying user entry with ID newuser_ds0 has been deleted from userstore-0')
        response = get(verify=self.dscfg.ssl_verify, url=self.dscfg.ds0_url + '/api/users/newuser_ds0',
                       auth=('am-identity-bind-account', 'password'))
        rest.check_http_status(http_result=response, expected_status=404)

        logger.test_step('Verifying user entry with ID newuser_ds0 has been deleted from userstore-1')
        response = get(verify=self.dscfg.ssl_verify, url=self.dscfg.ds1_url + '/api/users/newuser_ds0',
                       auth=('am-identity-bind-account', 'password'))
        rest.check_http_status(http_result=response, expected_status=404)

    @classmethod
    def teardown_class(cls):
        """Stop port-forward if needed"""

        cls.dscfg.stop_ds_port_forward(instance_nb=0)
        cls.dscfg.stop_ds_port_forward(instance_nb=1)

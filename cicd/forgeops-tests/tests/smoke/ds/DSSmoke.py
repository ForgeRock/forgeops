"""
Basic smoke test for DS.

Test is based on bidirectional sync with ldap configuration.

Contains CRUD on user operations + running replication.

Test are sorted automatically so that's why it's needed to keep test_0[1,2,3]_ naming.
"""
# Lib imports
import unittest
from requests import get, put, delete
import logging

# Framework imports
from config.ProductConfig import DSConfig


class DSSmoke(unittest.TestCase):
    dscfg = DSConfig()

    @classmethod
    def tearDownClass(self):
        """DSSmoke suite teardown"""
        self.dscfg.stop_ds_port_forward(instance_nb=0)
        self.dscfg.stop_ds_port_forward(instance_nb=1)

    def test_0_ping(self):
        """Pings OpenDJ instances to see if servers are alive"""
        response = get(verify=self.dscfg.ssl_verify, url=self.dscfg.ds0_rest_ping_url)
        self.assertEqual(response.status_code, 200, 'userstore-0 is alive')

        response = get(verify=self.dscfg.ssl_verify, url=self.dscfg.ds1_rest_ping_url)
        self.assertEqual(response.status_code, 200, 'userstore-1 is alive')

    def test_resource_replication(self):
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

        logging.info("Creating a new user entry with ID newuser_ds0")
        response = put(verify=self.dscfg.ssl_verify, url=self.dscfg.ds0_url + '/api/users/newuser_ds0',
                   auth=('am-identity-bind-account', 'password'), headers=headers,json=json_data)
        self.assertEqual(response.status_code, 201)

        logging.info("Verifying user entry with ID newuser_ds0 replicated in userstore-1")
        response = get(verify=self.dscfg.ssl_verify, url=self.dscfg.ds1_url + '/api/users/newuser_ds0',
                       auth=('am-identity-bind-account', 'password'))
        self.assertEqual(response.status_code, 200)

    @classmethod
    def tearDownClass(self):
        instance = DSSmoke()
        """Delete datastore resource from users/"""

        logging.info("Deleting user entry with ID newuser_ds0 from userstore-0")
        response = delete(verify=self.dscfg.ssl_verify, url=self.dscfg.ds0_url + '/api/users/newuser_ds0',
                          auth=('am-identity-bind-account', 'password'))
        self.assertEqual(instance, response.status_code, 200)

        logging.info("Verifying user entry with ID newuser_ds0 has been deleted from userstore-0")
        response = get(verify=self.dscfg.ssl_verify, url=self.dscfg.ds0_url + '/api/users/newuser_ds0',
                       auth=('am-identity-bind-account', 'password'))
        self.assertEqual(instance, response.status_code, 404)

        logging.info("Verifying user entry with ID newuser_ds0 has been deleted from userstore-1")
        response = get(verify=self.dscfg.ssl_verify, url=self.dscfg.ds1_url + '/api/users/newuser_ds0',
                       auth=('am-identity-bind-account', 'password'))
        self.assertEqual(instance, response.status_code, 404)

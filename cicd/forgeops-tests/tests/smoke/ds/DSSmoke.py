"""
Basic smoke test for DS.

Test is based on bidirectional sync with ldap configuration.

Contains CRUD on user operations + running replication.

Test are sorted automatically so that's why it's needed to keep test_0[1,2,3]_ naming.
"""
# Lib imports
import unittest
from requests import get

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
        resp = get(verify=self.dscfg.ssl_verify, url=self.dscfg.ds0_rest_ping_url)
        self.assertEqual(resp.status_code, 200, 'userstore-0 is alive')

        resp = get(verify=self.dscfg.ssl_verify, url=self.dscfg.ds1_rest_ping_url)
        self.assertEqual(resp.status_code, 200, 'userstore-1 is alive')

"""
Initial smoke tests for IG deployment
"""
import unittest
from requests import get

from config.ProductConfig import IGConfig


class IGSmoke(unittest.TestCase):
    igcfg = IGConfig()

    def test_ping(self):
        """Test to check if we get to IG landing page"""
        resp = get(verify=self.igcfg.ssl_verify, url=self.igcfg.ig_url)
        self.assertEqual(200, resp.status_code, "IG landing page")

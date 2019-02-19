# Copyright (c) 2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Life check test for DS product.
"""

# Lib imports
from requests import get

# Framework imports
from ProductConfig import DSConfig
from utils import logger, rest


class TestDS(object):
    dscfg = DSConfig()

    @classmethod
    def setup_class(cls):
        """Start port-forward if needed"""

        cls.dscfg.userstore0_popen = cls.dscfg.start_ds_port_forward(instance_name='userstore', instance_nb=0)
        cls.dscfg.userstore1_popen = cls.dscfg.start_ds_port_forward(instance_name='userstore', instance_nb=1)
        cls.dscfg.ctsstore0_popen = cls.dscfg.start_ds_port_forward(instance_name='ctsstore', instance_nb=0)
        cls.dscfg.configstore0_popen = cls.dscfg.start_ds_port_forward(instance_name='configstore', instance_nb=0)

    def test_0_ping(self):
        """Pings OpenDJ instances to see if servers are alive"""

        logger.test_step('Check userstore-0 is alive')
        response = get(verify=self.dscfg.ssl_verify, url=self.dscfg.userstore0_rest_ping_url)
        rest.check_http_status(http_result=response, expected_status=200)

        logger.test_step('Check userstore-1 is alive')
        response = get(verify=self.dscfg.ssl_verify, url=self.dscfg.userstore1_rest_ping_url)
        rest.check_http_status(http_result=response, expected_status=200)

        logger.test_step('Check ctsstore-0 is alive')
        response = get(verify=self.dscfg.ssl_verify, url=self.dscfg.ctsstore0_rest_ping_url)
        rest.check_http_status(http_result=response, expected_status=200)

        logger.test_step('Check configstore-0 is alive')
        response = get(verify=self.dscfg.ssl_verify, url=self.dscfg.configstore0_rest_ping_url)
        rest.check_http_status(http_result=response, expected_status=200)

    @classmethod
    def teardown_class(cls):
        """Stop port-forward if needed"""

        cls.dscfg.stop_ds_port_forward(instance_name='userstore', instance_nb=0)
        cls.dscfg.stop_ds_port_forward(instance_name='userstore', instance_nb=1)
        cls.dscfg.stop_ds_port_forward(instance_name='ctsstore', instance_nb=0)
        cls.dscfg.stop_ds_port_forward(instance_name='configstore', instance_nb=0)

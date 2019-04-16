# Copyright (c) 2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Life check test for IDM product.
"""

# Lib imports
from requests import get

# Framework imports
from ProductConfig import IDMConfig
from utils import logger, rest


class TestIDM(object):
    idmcfg = IDMConfig()

    def test_0_ping(self):
        """Pings OpenIDM to see if server is alive using admin headers"""

        logger.test_step('Ping OpenIDM')
        response = get(verify=self.idmcfg.ssl_verify, auth=('openidm-admin', 'openidm-admin'),
                       url=self.idmcfg.rest_ping_url)
        rest.check_http_status(http_result=response, expected_status=200)

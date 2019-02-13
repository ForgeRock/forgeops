# Copyright (c) 2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Life check test for AM product.
"""

# Lib imports
from requests import get

# Framework imports
from ProductConfig import AMConfig
from utils import logger, rest


class TestAM(object):
    amcfg = AMConfig()

    def test_0_ping(self):
        """Test if OpenAM is responding on isAlive endpoint"""

        logger.test_step('Ping OpenAM isAlive.jsp')
        response = get(verify=self.amcfg.ssl_verify, url=self.amcfg.am_url + '/isAlive.jsp')
        rest.check_http_status(http_result=response, expected_status=200)

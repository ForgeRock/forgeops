# Copyright (c) 2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Life check test for IG product.
"""

# Lib imports
from requests import get

# Framework imports
from ProductConfig import IGConfig
from utils import logger, rest


class TestIG(object):
    igcfg = IGConfig()

    def test_0_ping(self):
        """Test to check if we get to web page via IG reverse proxy"""

        logger.test_step('IG reverse proxy access')
        response = get(verify=self.igcfg.ssl_verify, url=self.igcfg.ig_url)
        rest.check_http_status(http_result=response, expected_status=200)

import os
os
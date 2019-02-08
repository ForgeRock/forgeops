# Copyright (c) 2016-2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Metadata related to kubernetes AM pods
"""

# Lib imports
import os
from requests import get, post

# Framework imports
from ProductConfig import AMConfig
from utils import logger, rest, kubectl
from utils.pod import Pod


class AMPod(Pod):
    PRODUCT_TYPE = 'openam'
    ROOT = os.path.join(os.sep, 'usr', 'local', 'tomcat')
    TEMP = os.path.join(ROOT, 'fr-tmp')

    def __init__(self, name, manifest_filepath):
        """
        :param name: Pod name
        :param manifest_filepath: Path to product manifest file
        """
        super().__init__(AMPod.PRODUCT_TYPE, name, manifest_filepath)

    def is_expected_version(self):
        """
        Return True if the version is as expected, otherwise assert.
        :return: True if the version is as expected.
        """

        amcfg = AMConfig()

        logger.info('Get admin token')
        headers = {'X-OpenAM-Username': 'amadmin', 'X-OpenAM-Password': 'password',
                   'Content-Type': 'application/json', 'Accept-API-Version': 'resource=2.0, protocol=1.0'}

        response = post(verify=amcfg.ssl_verify, url=amcfg.rest_authn_url, headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)
        admin_token = response.json()['tokenId']

        logger.info('Get AM version')
        headers = {'Content-Type': 'application/json', 'Accept-API-Version': 'resource=1.0',
                   'iplanetdirectorypro': admin_token}
        response = get(verify=amcfg.ssl_verify, url=amcfg.am_url + '/json/serverinfo/version', headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)

        logger.info('Check AM version')
        assert response.json()['version'] == self.manifest['version'], 'Unexpected AM version'
        assert response.json()['revision'] == self.manifest['revision'], 'Unexpected AM build revision'
        assert response.json()['date'] == self.manifest['date'], 'Unexpected AM build date'
        return True

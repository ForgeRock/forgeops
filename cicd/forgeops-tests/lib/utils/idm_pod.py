# Copyright (c) 2016-2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Metadata related to kubernetes IDM pod
"""

# Lib imports
import os
from requests import get

# Framework imports
from ProductConfig import IDMConfig
from utils import logger, rest, kubectl
from utils.pod import Pod


class IDMPod(Pod):
    PRODUCT_TYPE = 'openidm'
    ROOT = os.path.join(os.sep, 'opt', 'openidm')
#    TEMP = os.path.join(ROOT, 'fr-tmp')

    def __init__(self, name, manifest_filepath):
        """
        :param name: Pod name
        :param manifest_filepath: Path to product manifest file
        """
        super().__init__(IDMPod.PRODUCT_TYPE, name, manifest_filepath)

    def is_expected_version(self):
        """
        Return True if the version is as expected, otherwise assert.
        :return: True if the version is as expected.
        """
        idm_cfg = IDMConfig()

        logger.info("Get software version of the OpenIDM instance")
        headers = idm_cfg.get_admin_headers({'Content-Type': 'application/json'})
        response = get(verify=idm_cfg.ssl_verify, url=idm_cfg.idm_url + '/info/version', headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)

        logger.info('Check IDM version information')
        assert response.json()['productVersion'] == self.manifest['version'], 'Expected IDM version %s, but found %s' \
                                                                              % (self.manifest['version'],
                                                                                 response.json()['productVersion'])
        assert response.json()['productRevision'] == self.manifest['revision'], \
            'Expected IDM build revision %s, but found %s' % (self.manifest['revision'],
                                                              response.json()['productRevision'])
        assert response.json()['productBuildDate'] == self.manifest['date'], 'Expected IDM build date %s, but found %s' \
                                                                             % (self.manifest['date'],
                                                                                response.json()['productBuildDate'])
        return True

    def is_expected_commons_version(self):
        """
        Return True if config jar is the expected version
        :return: True if jar filename contains expected version
        """
        config_jar_path = os.path.join(IDMPod.ROOT, 'bundles', 'config-')
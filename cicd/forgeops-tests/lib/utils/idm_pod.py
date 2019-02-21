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
from utils import logger, rest
from utils.pod import Pod


class IDMPod(Pod):
    PRODUCT_TYPE = 'openidm'
    REPRESENTATIVE_COMMONS_JAR_NAME = 'config'

    def __init__(self, name):
        """
        :param name: Pod name
        """

        super().__init__(IDMPod.PRODUCT_TYPE, name)

    def is_expected_version(self):
        """
        Check if the version is as expected.
        """

        idm_cfg = IDMConfig()

        logger.info("Get software version of the OpenIDM instance")
        headers = idm_cfg.get_admin_headers({'Content-Type': 'application/json'})
        response = get(verify=idm_cfg.ssl_verify, url=idm_cfg.idm_url + '/info/version', headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)

        idm_metadata = {'TITLE': self.product_type,
                        'DESCRIPTION': self.name,
                        'VERSION': response.json()['productVersion'],
                        'REVISION': response.json()['productRevision'],
                        'DATE': response.json()['productBuildDate']}
        Pod.print_table(idm_metadata)

    def is_expected_commons_version(self):
        """Check if the commons version is as expected."""

        representative_commons_jar = IDMPod.REPRESENTATIVE_COMMONS_JAR_NAME
        lib_path = os.path.join(os.sep, 'opt', 'openidm', 'bundle')
        super(IDMPod, self).is_expected_versioned_commons_jar(lib_path, representative_commons_jar)

    def is_expected_jdk(self):
        """
        Check if Java is as expected.
        """

        super(IDMPod, self).is_expected_jdk({'openjdk version', 'openjdk version', 'openjdk version'})

    def is_expected_os(self):
        """
        Check if OS is as expected.
        """

        super(IDMPod, self).is_expected_os({'PRETTY_NAME', 'NAME', 'ID'})

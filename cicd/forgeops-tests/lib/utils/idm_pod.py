# Copyright (c) 2019 ForgeRock AS. Use of this source code is subject to the
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

    def version(self):
        """
        Return the product version information.
        :return: Dictionary
        """
        idm_cfg = IDMConfig()

        logger.info("Get software version of the OpenIDM instance")
        headers = idm_cfg.get_admin_headers({'Content-Type': 'application/json'})
        response = get(verify=idm_cfg.ssl_verify, url=idm_cfg.idm_url + '/info/version', headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)

        return {'TITLE': self.product_type,
                'DESCRIPTION': self.name,
                'VERSION': response.json()['productVersion'],
                'REVISION': response.json()['productRevision'],
                'DATE': response.json()['productBuildDate']}

    def log_commons_version(self):
        """Report version of commons for pod's forgerock product."""

        logger.debug('Report commons version for {name}'.format(name=self.name))
        representative_commons_jar = IDMPod.REPRESENTATIVE_COMMONS_JAR_NAME
        lib_path = os.path.join(os.sep, 'opt', 'openidm', 'bundle')
        super(IDMPod, self).log_versioned_commons_jar(lib_path, representative_commons_jar)

    def log_jdk(self):
        """Report Java version on the pod."""

        logger.debug('Report Java version for {name}'.format(name=self.name))
        super(IDMPod, self).log_jdk({'openjdk version', 'openjdk version', 'openjdk version'})

    def log_os(self):
        """Report Operating System on the pod."""

        logger.debug('Report OS version for {name}'.format(name=self.name))
        super(IDMPod, self).log_os({'PRETTY_NAME', 'NAME', 'ID'})

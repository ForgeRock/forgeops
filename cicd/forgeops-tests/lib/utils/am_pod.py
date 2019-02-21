# Copyright (c) 2016-2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Metadata related to a kubernetes AM pod.
"""

# Lib imports
import os
from requests import get, post

# Framework imports
from ProductConfig import AMConfig
from utils import logger, rest
from utils.pod import Pod


class AMPod(Pod):
    PRODUCT_TYPE = 'openam'
    REPRESENTATIVE_COMMONS_JAR_NAME = 'config'

    def __init__(self, name):
        """
        :param name: Pod name
        """
        super().__init__(AMPod.PRODUCT_TYPE, name)

    def get_version(self):
        """Get the application's version."""

        amcfg = AMConfig()

        logger.debug('Get admin token')
        headers = {'X-OpenAM-Username': 'amadmin', 'X-OpenAM-Password': 'password',
                   'Content-Type': 'application/json', 'Accept-API-Version': 'resource=2.0, protocol=1.0'}

        response = post(verify=amcfg.ssl_verify, url=amcfg.rest_authn_url, headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)
        admin_token = response.json()['tokenId']

        logger.debug('Get AM version')
        headers = {'Content-Type': 'application/json', 'Accept-API-Version': 'resource=1.0',
                   'iplanetdirectorypro': admin_token}
        response = get(verify=amcfg.ssl_verify, url=amcfg.am_url + '/json/serverinfo/version', headers=headers)
        rest.check_http_status(http_result=response, expected_status=200)

        version = response.json()['version']
        revision = response.json()['revision']
        date = response.json()['date']
        am_metadata = {'TITLE': self.product_type,
                       'DESCRIPTION': self.name,
                       'VERSION': version,
                       'REVISION': revision,
                       'DATE': date}

        return am_metadata

    def is_expected_version(self):
        """Check if the version is as expected."""

        am_metadata = self.get_version()
        Pod.print_table(am_metadata)

    def is_expected_commons_version(self):
        """Check if the commons version is as expected."""

        representative_commons_jar = AMPod.REPRESENTATIVE_COMMONS_JAR_NAME
        lib_path = os.path.join(os.sep, 'usr', 'local', 'tomcat', 'webapps', 'am', 'WEB-INF', 'lib', )
        super(AMPod, self).is_expected_versioned_commons_jar(lib_path, representative_commons_jar)

    def is_expected_jdk(self):
        """Check if jdk is as expected."""

        logger.debug('Check Java version for ' + self.name)
        return super(AMPod, self).is_expected_jdk({'openjdk version', 'openjdk version', 'openjdk version'})

    def is_expected_os(self):
        """Check if OS is as expected."""

        logger.debug('Check OS version for ' + self.name)
        super(AMPod, self).is_expected_os({'NAME', 'ID', 'VERSION_ID'})

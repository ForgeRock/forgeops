# Copyright (c) 2019 ForgeRock AS. Use of this source code is subject to the
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

    def version(self):
        """
        Return the product version information.
        :return: Dictionary
        """

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

    def log_commons_version(self):
        """Report version of commons for pod's forgerock product."""

        logger.debug('Report commons version for {name}'.format(name=self.name))
        representative_commons_jar = AMPod.REPRESENTATIVE_COMMONS_JAR_NAME
        lib_path = os.path.join(os.sep, 'usr', 'local', 'tomcat', 'webapps', 'am', 'WEB-INF', 'lib', )
        super(AMPod, self).log_versioned_commons_jar(lib_path, representative_commons_jar)

    def log_jdk(self):
        """Report Java version on the pod."""

        logger.debug('Report Java version for {name}'.format(name=self.name))
        return super(AMPod, self).log_jdk({'openjdk version', 'openjdk version', 'openjdk version'})

    def log_os(self):
        """Report Operating System on the pod."""

        logger.debug('Report OS version for {name}'.format(name=self.name))
        super(AMPod, self).log_os({'NAME', 'ID', 'VERSION_ID'})

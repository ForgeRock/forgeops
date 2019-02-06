# Copyright (c) 2016-2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Metadata related to kubernetes Amster pods
"""

# Lib imports
import os
# Framework imports
from utils import kubectl, logger
from utils.pod import Pod


class AmsterPod(Pod):
    PRODUCT_TYPE = 'amster'
    ROOT = os.path.join(os.sep, 'opt', 'amster')
    TEMP = os.path.join(ROOT, 'fr-tmp')

    def __init__(self, name, manifest_filepath):
        """
        :param name: Pod name
        :param manifest_filepath: Path to product manifest file
        """

        Pod.__init__(self, AmsterPod.PRODUCT_TYPE, name, manifest_filepath)
        self.manifest['amster_jvm'] = self.config[self.product_type]['amster_jvm']

    def is_expected_version(self):
        """
        Return True if the version is as expected, otherwise assert.
        :return: True if the version is as expected.
        """

        stdout, stderr = kubectl.exec(' '.join([self.name, '--', './amster', '--version']))
        version_strings = stdout[0].split()
        version = version_strings[3].lstrip('v')
        build = version_strings[5].rstrip(',')
        jvm = version_strings[7]

        logger.test_step('Check Amster version for pod: ' + self.name)
        assert version == self.manifest['version'], 'Unexpected Amster version'
        assert build == self.manifest['revision'], 'Unexpected Amster build revision'
        assert jvm == self.manifest['amster_jvm'], 'Unexpected JVM for amster'
        return True

    def is_expected_legal_notices(self):
        """
        Return True if legal notices are as expected, otherwise assert.
        :return: True if legal notices are as expected
        """

        legal_notices_directory = os.path.join(AmsterPod.ROOT, 'legal-notices')
        return super(AmsterPod, self).is_expected_legal_notices(legal_notices_directory)


    def setup_commons_check(self):
        """Setup for checking commons library version"""

        logger.debug('Setting up for commons version check')
        amster_version_jar = 'amster-%s.jar' % self.manifest['version']
        test_jar_filepath = os.path.join(AmsterPod.ROOT, amster_version_jar)
        return super(AmsterPod, self).setup_commons_check(test_jar_filepath, AmsterPod.TEMP)

    def cleanup_commons_check(self):
        """Cleanup after checking commons library version"""

        logger.debug('Cleaning up after commons version check')
        return super(AmsterPod, self).cleanup_commons_check(AmsterPod.TEMP)

    def is_expected_commons_version(self):
        """
        Return true if the commons version is as expected, otherwise return assert.
        This check inspects a sample commons .jar to see what version is in use.
        :return: True is the commons version is as expected.
        """

        logger.debug('Check commons version for config.jar')
        config_jar_properties = os.path.join('META-INF', 'maven', 'org.forgerock.commons', 'config', 'pom.properties')
        return super(AmsterPod, self).is_expected_commons_version(AmsterPod.TEMP, config_jar_properties)


    def is_expected_jdk(self):
        """
        Return True if jdk is as expected, otherwise assert.
        :return: True if jdk is as expected
        """

        return super(AmsterPod, self).is_expected_jdk(' '.join(['-c', 'amster', '--', 'java', '-version']))

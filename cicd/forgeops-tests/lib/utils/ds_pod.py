# Copyright (c) 2016-2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Metadata related to a kubernetes DS pod.
"""

# Lib imports
import os
import shutil
import zipfile
# Framework imports
from utils import logger, kubectl
from utils.pod import Pod


class DSPod(Pod):
    PRODUCT_TYPE = 'ds'
    ROOT = os.path.join(os.sep, 'opt', 'opendj')
    LOCAL_TEMP = os.path.join(os.sep, 'tmp', 'fr-tmp')
    REPRESENTATIVE_COMMONS_JAR_NAME = 'config'
    REPRESENTATIVE_COMMONS_JAR = REPRESENTATIVE_COMMONS_JAR_NAME + '.jar'

    def __init__(self, name):
        """
        :param name: Pod name
        """

        assert isinstance(name, str), 'Invalid name type %s' % type(name)

        super().__init__(DSPod.PRODUCT_TYPE, name)

    def get_version(self):
        """Get the application's version."""

        logger.debug('Get version for ' + self.name)
        stdout, ignored = kubectl.exec(
            Pod.NAMESPACE, [self.name, '-c', self.product_type, '--', 'bin/start-ds', '-F'])
        logger.debug('%s %s: %s' % (self.name, self.product_type, stdout[0]))
        attribute_of_interest = {'Build ID', 'Major Version', 'Minor Version', 'Point Version'}
        return Pod.get_metadata_of_interest('Version', self.name, stdout, attribute_of_interest)

    def is_expected_version(self):
        """Check the product version."""

        logger.debug('Check version for ' + self.name)
        version_metadata = self.get_version()
        Pod.print_table(version_metadata)

    def setup_commons_check(self):
        """Setup for checking commons library version."""

        logger.debug('Setting up for commons version check')
        source = os.path.join(DSPod.ROOT, 'lib', DSPod.REPRESENTATIVE_COMMONS_JAR)
        destination = os.path.join(DSPod.LOCAL_TEMP, self.name, DSPod.REPRESENTATIVE_COMMONS_JAR)
        kubectl.cp_from_pod(Pod.NAMESPACE, self.name, source, destination, self.product_type)

    def cleanup_commons_check(self):
        """Cleanup for checking commons library version."""

        logger.debug('Cleaning up after commons version check')
        shutil.rmtree(os.path.join(DSPod.LOCAL_TEMP, self.name))

    def is_expected_commons_version(self):
        """Check the commons library version."""

        logger.debug('Check commons version for ' + self.name + ':' + DSPod.REPRESENTATIVE_COMMONS_JAR)
        test_temp = os.path.join(DSPod.LOCAL_TEMP, self.name)
        test_file_path = os.path.join(test_temp, DSPod.REPRESENTATIVE_COMMONS_JAR)
        assert os.path.isfile(test_file_path), 'Failed to find ' + test_file_path
        explode_directory = os.path.join(test_temp, DSPod.REPRESENTATIVE_COMMONS_JAR_NAME)
        with zipfile.ZipFile(test_file_path) as commons_zip_file:
            commons_zip_file.extractall(explode_directory)

        test_jar_properties_path = os.path.join(explode_directory, 'META-INF', 'maven', 'org.forgerock.commons',
                                                DSPod.REPRESENTATIVE_COMMONS_JAR_NAME, 'pom.properties')
        logger.debug("Checking commons version in " + test_jar_properties_path)
        assert os.path.isfile(test_jar_properties_path), 'Failed to find ' + test_jar_properties_path

        with open(test_jar_properties_path) as fp:
            lines = fp.readlines()

        attribute_of_interest = {'version', 'groupId', 'artifactId'}
        os_metadata = Pod.get_metadata_of_interest('Commons', self.name, lines, attribute_of_interest)
        Pod.print_table(os_metadata)

    def is_expected_jdk(self):
        """Check the Java version."""

        logger.debug('Check Java version for ' + self.name)
        metadata, ignored = kubectl.exec(
            Pod.NAMESPACE, [self.name, '-c', self.product_type, '--', 'bin/start-ds', '-s'])
        attribute_of_interest = {'JAVA Version', 'JAVA Vendor', 'JVM Version'}
        os_metadata = Pod.get_metadata_of_interest('JAVA', self.name, metadata, attribute_of_interest)
        Pod.print_table(os_metadata)

    def is_expected_os(self):
        """Check the Operating System version."""

        logger.debug('Check OS version for ' + self.name)
        return super(DSPod, self).is_expected_os({'PRETTY_NAME', 'NAME', 'ID'})

# Copyright (c) 2016-2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Metadata related to kubernetes pods
"""
# Lib imports
import os
from configparser import ConfigParser
import multiset

# Framework imports
from utils import logger, kubectl


class Pod(object):

    def __init__(self, product_type, name, manifest_filepath):
        """
        :param product_type: ForgeRock Platform product type
        :param name: Pod name
        :param manifest_filepath: Path to product manifest file
        """
        self._product_type = product_type
        self._name = name
        self._config = ConfigParser()
        assert os.path.exists(manifest_filepath), 'Unable to locate ' + manifest_filepath
        self._config.read(manifest_filepath)

        self._manifest = {'version': self._config[product_type]["version"],
                          'revision': self._config[product_type]["revision"],
                          'date': self._config[product_type]["date"],
                          'jdk_version': self._config[product_type]["jdk_version"],
                          'jre_version': self._config[product_type]["jre_version"],
                          'jdk_full_version': self._config[product_type]["jdk_full_version"],
                          'commons_version': self._config[product_type]["commons_version"]}

    @property
    def product_type(self):
        return self._product_type

    @property
    def name(self):
        return self._name

    @property
    def config(self):
        return self._config

    @property
    def manifest(self):
        return self._manifest

    @staticmethod
    def is_expected_am_amster_version(am_manifest, amster_manifest):
        """
        :param am_manifest: Manifest of version information
        :param amster_manifest: Manifest of version information
        Return True if the AM and Amster versions match, otherwise assert.
        :return: True if the versions are as expected.
        """

        logger.debug('Checking AM and Amster versions match')
        assert am_manifest['version'] == amster_manifest['version'], 'AM and Amster versions should match'
        assert am_manifest['revision'] == amster_manifest['revision'], 'AM and Amster build revisions should match'
        assert am_manifest['date'] == amster_manifest['date'], 'AM and Amster build date should match'
        assert am_manifest['commons_version'] == amster_manifest['commons_version'], 'AM and Amster commons version should match'

        if am_manifest['jdk_version'] != amster_manifest['jdk_version']:
            logger.warning("Different versions of java are in use.")


    def is_expected_version(self):
        """
        Return True if the version is as expected, otherwise assert.
        :return: True if the version is as expected.
        """
        assert False, 'Not implemented, please override in subclass'

    def is_expected_legal_notices(self, legal_notices_path):
        """
        :param legal_notices_path: Path to legal notices
        Return True if legal notices are as expected, otherwise assert.
        :return: True if legal notices are as expected
        """

        default_legal_notices = set(self._config["DEFAULT"]["legal_notices"].split())
        legal_notices = multiset.Multiset(self._config[self.product_type]["legal_notices"].split())
        legal_notices += default_legal_notices

        stdout, stderr =  kubectl.exec(' '.join([self.name, '-- ls -R ' + legal_notices_path]))
        for line in stdout:
            logger.debug('Found legal notice ' + self.name)
            if line:
                legal_notices.remove(line, 1)
        assert len(legal_notices) == 0, 'Did not find all legal notices'
        return True

    def setup_commons_check(self):
        """Setup for checking commons library version"""
        assert False, 'Not implemented, please override in subclass'

    def cleanup_commons_check(self):
        """Cleanup after checking commons library version"""
        assert False, 'Not implemented, please override in subclass'

    def is_expected_commons_version(self):
        """
        Return true if the commons version is as expected, otherwise return assert.
        This check inspects a sample commons .jar to see what version is in use.
        :return: True is the commons version is as expected.
        """
        assert False, 'Not implemented, please override in subclass'


    def setup_commons_check(self, filepath, temp_directory):
        """
        :param filepath Path to a common .jar
        :param temp_directory directory used for exploding the sample .jar file
        Setup for checking commons library version
        """

        logger.debug('Setting up for commons version check')
        ignored = kubectl.exec(' '.join([self.name, '-- unzip', filepath, '-d', temp_directory]))

    def cleanup_commons_check(self, temp_directory):
        """
        :param temp_directory Directory to be deleted
        Cleanup after checking commons library version
        """

        logger.debug('Cleaning up after commons version check')
        ignored, ignored = kubectl.exec(' '.join([self.name, '-- rm', '-rf', temp_directory]))

    def is_expected_commons_version(self, subpath, temp_directory):
        """
        Return true if the commons version is as expected, otherwise return assert.
        This check inspects a sample commons .jar to see what version is in use.
        :return: True is the commons version is as expected.
        """

        test_filepath = os.path.join(temp_directory, subpath, temp_directory)
        stdout, stderr = kubectl.exec \
            (' '.join([self.name, '--', 'cat', test_filepath]))

        logger.debug('Check commons version for: ' +  self.name)
        assert stdout[2].strip() == 'version=' + self.manifest['commons_version'], 'Unexpected commons version'
        assert stdout[3].strip() == 'groupId=org.forgerock.commons', ' Unexpected groupId for commons library'
        return True


    def is_expected_jdk(self, sub_command):
        """
        :param sub_command: Command passed onto kubectl to obtain jdk version information.
        Return True if jdk is as expected, otherwise assert.
        :return: True if jdk is as expected
        """

        stdout, stderr = kubectl.exec(' '.join([self.name, sub_command]))

        logger.debug('Check JDK version for ' + self.name)
        assert stderr[0].strip() == self.manifest['jdk_version'], 'Unexpected JDK in use'  # TODO: why stderr
        assert stderr[1].strip() == self.manifest['jre_version'], 'Unexpected JRE in use'
        assert stderr[2].strip() == self.manifest['jdk_full_version'], 'Unexpected JDK in use'
        return True

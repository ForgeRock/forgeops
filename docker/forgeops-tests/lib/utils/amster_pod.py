# Copyright (c) 2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Metadata related to a kubernetes Amster pod.
"""

# Lib imports
import os
import shutil
import zipfile
# Framework imports
from utils import kubectl, logger
from utils.pod import Pod


class AmsterPod(Pod):
    PRODUCT_TYPE = 'amster'
    ROOT = os.path.join(os.sep, 'opt', 'amster')
    LOCAL_TEMP = os.path.join(os.sep, 'tmp', 'fr-tmp')
    REPRESENTATIVE_COMMONS_JAR_NAME = 'config'
    REPRESENTATIVE_COMMONS_JAR = REPRESENTATIVE_COMMONS_JAR_NAME + '.jar'

    def __init__(self, name):
        """
        :param name: Pod name
        """

        super().__init__(AmsterPod.PRODUCT_TYPE, name)

    def version(self):
        """
        Return the product version information.
        :return: Dictionary
        """

        logger.test_step('Report Amster version for pod {name}'.format(name=self.name))
        stdout, ignored = kubectl.exec(
            Pod.NAMESPACE, [self.name, '--', './amster', '-c', self.product_type, '--version'])
        version_text = stdout[0].strip()

        version_key = 'Amster OpenAM Shell v'
        build_key = ' build '
        revision_length = 10
        build_position = version_text.find(build_key)
        version = version_text[len(version_key): build_position]
        start = build_position + len(build_key)
        revision = version_text[start: start + revision_length]

        amster_metadata = {'TITLE': self.product_type,
                           'DESCRIPTION': self.name,
                           'VERSION_TEXT': version_text,
                           'VERSION': version,
                           'REVISION': revision}

        return amster_metadata

    def setup_commons_check(self):
        """Setup for checking commons library version."""

        logger.debug('Setting up for commons version check')
        source = os.path.join(AmsterPod.ROOT)
        destination = os.path.join(AmsterPod.LOCAL_TEMP, self.name)
        kubectl.cp_from_pod(Pod.NAMESPACE, self.name, source, destination, self.product_type)

    def cleanup_commons_check(self):
        """Cleanup for checking commons library version."""

        logger.debug('Cleaning up after commons version check')
        shutil.rmtree(os.path.join(AmsterPod.LOCAL_TEMP, self.name))

    def log_commons_version(self):
        """Report version of commons for pod's forgerock product."""

        logger.debug('Check commons version for {name}:{commons_jar}'.
                     format(name=self.name, commons_jar=AmsterPod.REPRESENTATIVE_COMMONS_JAR))
        test_temp = os.path.join(AmsterPod.LOCAL_TEMP, self.name)
        stdout, ignored = kubectl.exec(
            Pod.NAMESPACE, [self.name, '-c', self.product_type, '--', 'find', AmsterPod.ROOT, '-name', 'amster-*.jar'])
        amster_filepath = stdout[0]
        head, tail = os.path.split(amster_filepath)  # get versioned amster jar name
        exploded_directory = os.path.join(test_temp, 'exploded')
        amster_jar_filepath = os.path.join(test_temp, tail)
        with zipfile.ZipFile(amster_jar_filepath) as commons_zip_file:
            commons_zip_file.extractall(exploded_directory)

        test_jar_properties_path = os.path.join(exploded_directory, 'META-INF', 'maven', 'org.forgerock.commons',
                                                AmsterPod.REPRESENTATIVE_COMMONS_JAR_NAME, 'pom.properties')
        logger.debug('Checking commons version in {path}'.format(path=test_jar_properties_path))
        assert os.path.isfile(test_jar_properties_path), 'Failed to find {path}'.format(path=test_jar_properties_path)

        with open(test_jar_properties_path) as file_pointer:
            lines = file_pointer.readlines()

        attribute_of_interest = {'version', 'groupId', 'artifactId'}
        os_metadata = Pod.get_metadata_of_interest('Commons', self.name, lines, attribute_of_interest)
        Pod.print_table(os_metadata)

    def log_jdk(self):
        """Report Java version on the pod."""

        logger.debug('Report Java version for {name}'.format(name=self.name))
        super(AmsterPod, self).log_jdk({'openjdk version', 'openjdk version', 'openjdk version'})

    def log_os(self):
        """Report Operating System on the pod."""

        logger.debug('Report OS version for {name}'.format(name=self.name))
        return super(AmsterPod, self).log_os({'NAME', 'ID', 'VERSION_ID'})

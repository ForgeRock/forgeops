# Copyright (c) 2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Metadata related to a kubernetes AM pod.
"""

# Lib imports
import os

# Framework imports
from utils import logger, kubectl
from utils.pod import Pod


class IGPod(Pod):
    PRODUCT_TYPE = 'openig'
    REPRESENTATIVE_COMMONS_JAR_NAME = 'config'
    ROOT = os.path.join(os.sep, 'usr', 'local', 'tomcat')

    def __init__(self, name):
        """
        :param name: Pod name
        """
        super().__init__(IGPod.PRODUCT_TYPE, name)

    def version(self):
        """
        Return the product version information.
        :return: Dictionary
        """

        logger.test_step('Report IG version for pod {name}'.format(name=self.name))


        test_jar_properties_path = os.path.join(IGPod.ROOT, 'webapps', 'ROOT', 'META-INF', 'maven', 'org.forgerock.openig', 'openig-war',
                                                'pom.properties')
        attributes_of_interest = {'version', 'groupId', 'artifactId'}
        metadata, ignored = kubectl.exec(
            Pod.NAMESPACE, [self.name, '-c', self.product_type, '--', 'cat', test_jar_properties_path])
        version_metadata = Pod.get_metadata_of_interest(self.product_type, self.name, metadata, attributes_of_interest)
        return version_metadata

    def log_commons_version(self):
        """Report version of commons for pod's forgerock product."""

        logger.debug('Report commons version for {name}'.format(name=self.name))
        representative_commons_jar = IGPod.REPRESENTATIVE_COMMONS_JAR_NAME
        lib_path = os.path.join(os.sep, 'usr', 'local', 'tomcat', 'webapps', 'ROOT', 'WEB-INF', 'lib', )
        super(IGPod, self).log_versioned_commons_jar(lib_path, representative_commons_jar)

    def log_jdk(self):
        """Report Java version on the pod."""

        logger.debug('Report Java version for {name}'.format(name=self.name))
        return super(IGPod, self).log_jdk({'openjdk version', 'openjdk version', 'openjdk version'})

    def log_os(self):
        """Report Operating System on the pod."""

        logger.debug('Report OS version for {name}'.format(name=self.name))
        super(IGPod, self).log_os({'NAME', 'ID', 'VERSION_ID'})        
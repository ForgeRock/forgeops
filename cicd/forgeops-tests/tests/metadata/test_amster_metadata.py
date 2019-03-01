# Copyright (c) 2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Verify the versions of ForgeRock Product in use.
"""

# Lib imports
import pytest

# Framework imports
from utils import logger, kubectl, pod
from utils.amster_pod import AmsterPod

#TODO checksum check on docker images


class TestAmsterMetadata(object):
    pods = []

    @classmethod
    def setup_class(cls):
        """Populate the lists of pods"""

        logger.test_step('Get pods')
        podnames = kubectl.get_product_component_names(pod.Pod.NAMESPACE, AmsterPod.PRODUCT_TYPE)
        assert len(podnames) > 0,  'There are no Amster pods'
        for podname in podnames:
            TestAmsterMetadata.pods.append(AmsterPod(podname))

    def test_version(self):
        """Report the version"""

        logger.test_step('Report the version')
        for amster_pod in TestAmsterMetadata.pods:
            logger.info('Report the version for {name}'.format(name=amster_pod.name))
            amster_pod.log_version()

    @pytest.fixture()
    def get_commons_library(self):
        """Setup and cleanup for checking commons library version"""

        for amster_pod in TestAmsterMetadata.pods:
            logger.test_step('Setting up for commons version check for {name}'.format(name=amster_pod.name))
            amster_pod.setup_commons_check()
        yield
        for amster_pod in TestAmsterMetadata.pods:
            logger.test_step('Cleaning up after commons version check for {name}'.format(name=amster_pod.name))
            amster_pod.cleanup_commons_check()

    def test_commons_version(self, get_commons_library):
        """Report the version of a commons library"""

        logger.test_step('Report commons version')
        for amster_pod in TestAmsterMetadata.pods:
            logger.info('Report commons version for {name}'.format(name=amster_pod.name))
            amster_pod.log_commons_version()

    def test_legal_notices(self):
        """Check the presence of legal-notices"""

        logger.test_step('Check legal notices')
        for amster_pod in TestAmsterMetadata.pods:
            logger.info('Check legal-notices exist for {name}'.format(name=amster_pod.name))
            amster_pod.are_legal_notices_present()

    def test_pods_jdk(self):
        """Report the JDK running in the pods"""

        logger.test_step('Report Java version')
        for amster_pod in TestAmsterMetadata.pods:
            logger.info('Report Java version for {name}'.format(name=amster_pod.name))
            amster_pod.log_jdk()

    def test_image_os(self):
        """Report the OS for the pods"""

        logger.test_step('Report the operating system')
        for amster_pod in TestAmsterMetadata.pods:
            logger.info('Report OS for {name}'.format(name=amster_pod.name))
            amster_pod.log_os()

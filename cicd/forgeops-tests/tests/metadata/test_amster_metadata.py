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

    @pytest.fixture()
    def get_commons_library(self):
        """Setup and cleanup for checking commons library version"""

        for amster_pod in TestAmsterMetadata.pods:
            logger.test_step('Setting up for commons version check for: ' + amster_pod.name)
            amster_pod.setup_commons_check()
        yield
        for amster_pod in TestAmsterMetadata.pods:
            logger.test_step('Cleaning up after commons version check for: ' + amster_pod.name)
            amster_pod.cleanup_commons_check()

    def test_commons_version(self, get_commons_library):
        """Check the version of a commons library"""

        logger.test_step('Check commons version')
        for amster_pod in TestAmsterMetadata.pods:
            logger.info('Check commons version for: ' + amster_pod.name)
            amster_pod.is_expected_commons_version()

    def test_legal_notices(self):
        """Check the presence of legal-notices"""

        logger.test_step('Check legal notices')
        for amster_pod in TestAmsterMetadata.pods:
            logger.info('Check legal-notices exist for: ' + amster_pod.name)
            amster_pod.is_expected_legal_notices()

    def test_version(self):
        """Check the version"""

        logger.test_step('Check version')
        for amster_pod in TestAmsterMetadata.pods:
            logger.info('Check JDK version for ' + amster_pod.name)
            amster_pod.is_expected_version()

    def test_pods_jdk(self):
        """Check the JDK running in the pods"""

        logger.test_step('Check Jaa version')
        for amster_pod in TestAmsterMetadata.pods:
            logger.info('Check Java version for ' + amster_pod.name)
            amster_pod.is_expected_jdk()

    def test_image_os(self):
        """Check the OS for the pods"""

        logger.test_step('Check the operating system')
        for amster_pod in TestAmsterMetadata.pods:
            logger.info('Check OS for ' + amster_pod.name)
            amster_pod.is_expected_os()

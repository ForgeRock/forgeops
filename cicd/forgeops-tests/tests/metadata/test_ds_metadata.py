# Copyright (c) 2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Verify the versions of ForgeRock Product in use.
"""

# Lib imports
import pytest

# Framework imports
from utils import logger, kubectl, pod
from utils.ds_pod import DSPod

# TODO checksum check on docker images


class TestDSMetadata(object):
    pods = []

    @classmethod
    def setup_class(cls):
        """Populate the lists of pods"""

        logger.test_step('Get pods')
        podnames = kubectl.get_product_component_names(pod.Pod.NAMESPACE, DSPod.PRODUCT_TYPE)
        assert len(podnames) > 0,  'There are no DS pods'
        for podname in podnames:
            TestDSMetadata.pods.append(DSPod(podname))

    def test_version(self):
        """Check the version"""

        logger.test_step('Check product version')
        for ds_pod in TestDSMetadata.pods:
            ds_pod.is_expected_version()

    @pytest.fixture()
    def __get_commons_library(self):
        """Setup and cleanup for checking commons library version"""

        for ds_pod in TestDSMetadata.pods:
            logger.test_step('Setting up for commons version check for: ' + ds_pod.name)
            ds_pod.setup_commons_check()
        yield
        for ds_pod in TestDSMetadata.pods:
            logger.test_step('Cleaning up after commons version check for: ' + ds_pod.name)
            ds_pod.cleanup_commons_check()

    def test_commons_version(self, __get_commons_library):
        """Check the version of a commons library"""

        logger.test_step('Check commons version')
        for ds_pod in TestDSMetadata.pods:
            logger.info('Check commons version for: ' + ds_pod.name)
            ds_pod.is_expected_commons_version()

    def test_legal_notices(self):
        """Check the presence of legal-notices"""

        logger.test_step('Check legal notices')
        for ds_pod in TestDSMetadata.pods:
            logger.info('Check legal-notices exist for: ' + ds_pod.name)
            ds_pod.is_expected_legal_notices()

    def test_pods_jdk(self):
        """Check Java running in the pods"""

        logger.test_step('Check Java version')
        for ds_pod in TestDSMetadata.pods:
            logger.info('Check Java version for ' + ds_pod.name)
            ds_pod.is_expected_jdk()

    def test_image_os(self):
        """Check the os for the pods"""

        logger.test_step('Check the operating system')
        for ds_pod in TestDSMetadata.pods:
            logger.info('Check OS for ' + ds_pod.name)
            ds_pod.is_expected_os()

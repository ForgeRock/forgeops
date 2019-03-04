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
        """Report the version"""

        logger.test_step('Report the version')
        for ds_pod in TestDSMetadata.pods:
            logger.info('Report the version for {name}'.format(name=ds_pod.name))
            ds_pod.log_version()

    @pytest.fixture()
    def __get_commons_library(self):
        """Setup and cleanup for checking commons library version"""

        for ds_pod in TestDSMetadata.pods:
            logger.test_step('Setting up for commons version check for {name}'.format(name=ds_pod.name))
            ds_pod.setup_commons_check()
        yield
        for ds_pod in TestDSMetadata.pods:
            logger.test_step('Cleaning up after commons version check for {name}'.format(name=ds_pod.name))
            ds_pod.cleanup_commons_check()

    def test_commons_version(self, __get_commons_library):
        """Report the version of a commons library"""

        logger.test_step('Report commons version')
        for ds_pod in TestDSMetadata.pods:
            logger.info('Report commons version for {name}'.format(name=ds_pod.name))
            ds_pod.log_commons_version()

    def test_legal_notices(self):
        """Check the presence of legal-notices"""

        logger.test_step('Check legal notices')
        for ds_pod in TestDSMetadata.pods:
            logger.info('Check legal-notices exist for {name}'.format(name=ds_pod.name))
            ds_pod.are_legal_notices_present()

    def test_pods_jdk(self):
        """Report Java running in the pods"""

        logger.test_step('Report Java version')
        for ds_pod in TestDSMetadata.pods:
            logger.info('Report Java version for {name}'.format(name=ds_pod.name))
            ds_pod.log_jdk()

    def test_image_os(self):
        """Report the os for the pods"""

        logger.test_step('Report the operating system')
        for ds_pod in TestDSMetadata.pods:
            logger.info('Report OS for {name}'.format(name=ds_pod.name))
            ds_pod.log_os()

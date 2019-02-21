# Copyright (c) 2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Verify the versions of ForgeRock Product in use.
"""

# Lib imports
# Framework imports
from utils import logger, kubectl, pod
from utils.am_pod import AMPod

# TODO checksum check on docker images


class TestAMMetadata(object):
    pods = []

    @classmethod
    def setup_class(cls):
        """Populate the lists of pods"""

        logger.test_step('Get pods')
        podnames = kubectl.get_product_component_names(pod.Pod.NAMESPACE, AMPod.PRODUCT_TYPE)
        assert len(podnames) > 0,  'There are no AM pods'
        for podname in podnames:
            TestAMMetadata.pods.append(AMPod(podname))

    def test_version(self):
        """Check the version"""

        logger.test_step('Check the version')
        representative_pod = TestAMMetadata.pods[0]
        representative_pod.is_expected_version()

    def test_commons_version(self):
        """Check the version of a commons library"""

        logger.test_step('Check commons version')
        for am_pod in TestAMMetadata.pods:
            logger.info('Check commons version for: ' + am_pod.name)
            am_pod.is_expected_commons_version()

    def test_legal_notices(self):
        """Check the presence of legal-notices"""

        logger.test_step('Check legal notices')
        for am_pod in TestAMMetadata.pods:
            logger.info('Check legal-notices exist for: ' + am_pod.name)
            am_pod.is_expected_legal_notices()

    def test_pods_jdk(self):
        """Check the Java for the pods"""

        logger.test_step('Check Java version')
        for am_pod in TestAMMetadata.pods:
            logger.info('Check Java version for ' + am_pod.name)
            am_pod.is_expected_jdk()

    def test_image_os(self):
        """Check the OS for the pods"""

        logger.test_step('Check the operating system')
        for am_pod in TestAMMetadata.pods:
            logger.info('Check OS for ' + am_pod.name)
            am_pod.is_expected_os()

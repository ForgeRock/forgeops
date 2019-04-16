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
        """Report the version"""

        logger.test_step('Report the version')
        representative_pod = TestAMMetadata.pods[0]
        logger.info('Report version for {name}'.format(name=representative_pod.name))
        representative_pod.log_version()

    def test_commons_version(self):
        """Report the version of a commons library"""

        logger.test_step('Report commons version')
        for am_pod in TestAMMetadata.pods:
            logger.info('Report commons version for {name}'.format(name=am_pod.name))
            am_pod.log_commons_version()

    def test_legal_notices(self):
        """Check the presence of legal-notices"""

        logger.test_step('Check legal notices')
        for am_pod in TestAMMetadata.pods:
            logger.info('Check legal-notices exist for {name}'.format(name=am_pod.name))
            am_pod.are_legal_notices_present()

    def test_pods_jdk(self):
        """Report the Java for the pods"""

        logger.test_step('Report Java version')
        for am_pod in TestAMMetadata.pods:
            logger.info('Report Java version for {name}'.format(name=am_pod.name))
            am_pod.log_jdk()

    def test_image_os(self):
        """Report the OS for the pods"""

        logger.test_step('Report the operating system')
        for am_pod in TestAMMetadata.pods:
            logger.info('Report OS for {name}'.format(name=am_pod.name))
            am_pod.log_os()

# Copyright (c) 2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Verify the versions of ForgeRock Product in use.
"""

# Lib imports
# Framework imports
from utils import logger, kubectl, pod
from utils.ig_pod import IGPod


class TestIGMetadata(object):
    pods = []

    @classmethod
    def setup_class(cls):
        """Populate the lists of pods"""

        logger.test_step('Get pods')
        podnames = kubectl.get_product_component_names(pod.Pod.NAMESPACE, IGPod.PRODUCT_TYPE)
        assert len(podnames) > 0,  'There are no IG pods'
        for podname in podnames:
            TestIGMetadata.pods.append(IGPod(podname))

    def test_version(self):
        """Report the version"""

        logger.test_step('Report the version')
        for ig_pod in TestIGMetadata.pods:
            logger.info('Report the version for {name}'.format(name=ig_pod.name))
            ig_pod.log_version()

    def test_commons_version(self):
        """Report the commons version"""

        logger.test_step('Report the commons version')
        for ig_pod in TestIGMetadata.pods:
            logger.info('Report commons version for {name}'.format(name=ig_pod.name))
            ig_pod.log_commons_version()

    def test_legal_notices(self):
        """Report the presence of legal-notices"""

        logger.test_step('Check legal Notices')
        for ig_pod in TestIGMetadata.pods:
            logger.info('Check legal-notices exist for {name}'.format(name=ig_pod.name))
            ig_pod.are_legal_notices_present()

    def test_jdk_version(self):
        """Report Java running in the pods"""

        logger.test_step('Report the Java version')
        for ig_pod in TestIGMetadata.pods:
            logger.info('Report Java version for {name}'.format(name=ig_pod.name))
            ig_pod.log_jdk()

    def test_image_os(self):
        """Check the OS running in the pods"""

        logger.test_step('Report the operating system')
        for ig_pod in TestIGMetadata.pods:
            logger.info('Report OS for {name}'.format(name=ig_pod.name))
            ig_pod.log_os()

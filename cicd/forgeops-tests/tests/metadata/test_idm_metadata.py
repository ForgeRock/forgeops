# Copyright (c) 2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Verify the versions of ForgeRock Product in use.
"""

# Lib imports
# Framework imports
from utils import logger, kubectl, pod
from utils.idm_pod import IDMPod


class TestIDMMetadata(object):
    pods = []

    @classmethod
    def setup_class(cls):
        """Populate the lists of pods"""

        logger.test_step('Get pods')
        podnames = kubectl.get_product_component_names(pod.Pod.NAMESPACE, IDMPod.PRODUCT_TYPE)
        assert len(podnames) > 0,  'There are no IDM pods'
        for podname in podnames:
            TestIDMMetadata.pods.append(IDMPod(podname))

    def test_version(self):
        """Check the version"""

        logger.test_step('Check the version')
        self.pods[0].is_expected_version()

    def test_commons_version(self):
        """Check the commons version"""

        logger.test_step('Check the commons version')
        self.pods[0].is_expected_commons_version()

    def test_legal_notices(self):
        """Check the presence of legal-notices"""

        logger.test_step('Check legal Notices')
        for idm_pod in TestIDMMetadata.pods:
            logger.info('Check legal-notices exist for: ' + idm_pod.name)
            idm_pod.is_expected_legal_notices()

    def test_jdk_version(self):
        """Check Java running in the pods"""

        logger.test_step('Check legal Notices')
        TestIDMMetadata.pods[0].is_expected_jdk()

    def test_image_os(self):
        """Check the OS running in the pods"""

        logger.test_step('Check the operating system')
        for idm_pod in TestIDMMetadata.pods:
            logger.info('Check OS for ' + idm_pod.name)
            idm_pod.is_expected_os()

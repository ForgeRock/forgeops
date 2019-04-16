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
        """Report the version"""

        logger.test_step('Report the version')
        representative_pod = self.pods[0]
        logger.info('Report the version for {name}'.format(name=representative_pod.name))
        representative_pod.log_version()

    def test_commons_version(self):
        """Report the commons version"""

        logger.test_step('Report the commons version')
        for idm_pod in TestIDMMetadata.pods:
            logger.info('Report commons version for {name}'.format(name=idm_pod.name))
            idm_pod.log_commons_version()

    def test_legal_notices(self):
        """Report the presence of legal-notices"""

        logger.test_step('Check legal Notices')
        for idm_pod in TestIDMMetadata.pods:
            logger.info('Check legal-notices exist for {name}'.format(name=idm_pod.name))
            idm_pod.are_legal_notices_present()

    def test_jdk_version(self):
        """Report Java running in the pods"""

        logger.test_step('Report the Java version')
        for idm_pod in TestIDMMetadata.pods:
            logger.info('Report Java version for {name}'.format(name=idm_pod.name))
            idm_pod.log_jdk()

    def test_image_os(self):
        """Check the OS running in the pods"""

        logger.test_step('Report the operating system')
        for idm_pod in TestIDMMetadata.pods:
            logger.info('Report OS for {name}'.format(name=idm_pod.name))
            idm_pod.log_os()

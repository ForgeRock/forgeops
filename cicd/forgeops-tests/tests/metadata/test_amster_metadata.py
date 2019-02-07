# Copyright (c) 2016-2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Verify the versions of ForgeRock Product in use.
"""

# Lib imports
import os
import pytest

# Framework imports
from utils import logger, kubectl, pod, am_pod
from utils.amster_pod import AmsterPod

#TODO checksum check on docker images


class TestAmsterMetadata(object):
    MANIFEST_FILEPATH = os.path.join(pod.Pod.test_root_directory(), 'config', '6.5.0-manifest.txt')
    pods = []

    @classmethod
    def setup_class(cls):
        """Populate the lists of pods"""

        logger.test_step('Get pods')
        environment_properties = dict(os.environ)
        podnames = kubectl.get_product_pod_names(AmsterPod.PRODUCT_TYPE, environment_properties.get('TESTS_NAMESPACE'))
        assert len(podnames) > 0,  'There are no Amster pods'
        for podname in podnames:
            TestAmsterMetadata.pods.append(AmsterPod(podname, TestAmsterMetadata.MANIFEST_FILEPATH))

    def test_am_amster_versions(self):
        """Check the AM and Amster versions match"""

        logger.test_step('Check AM and Amster versions match')
        representative_amster_pod = TestAmsterMetadata.pods[0]
        representative_am_pod =  am_pod.AMPod("representative_openam_pod", TestAmsterMetadata.MANIFEST_FILEPATH)
        pod.Pod.is_expected_am_amster_version(representative_am_pod.manifest, representative_amster_pod.manifest)


    @pytest.fixture()
    def get_commons_library(self):
        """Setup and cleanup for checking commons library version"""

        for pod in TestAmsterMetadata.pods:
            logger.test_step('Setting up for commons version check for: ' + pod.name)
            pod.setup_commons_check()
        yield
        for pod in TestAmsterMetadata.pods:
            logger.test_step('Cleaning up after commons version check for: ' + pod.name)
            pod.cleanup_commons_check()

    def test_commons_version(self, get_commons_library):
        """Check the version of a commons library"""

        logger.test_step('Check commons version')
        for pod in TestAmsterMetadata.pods:
            logger.info('Check commons version for: ' +  pod.name)
            pod.is_expected_commons_version()


    def test_legal_notices(self):
        """Check the presence of legal-notices"""

        logger.test_step('Check legal Notices')
        for pod in TestAmsterMetadata.pods:
            logger.info('Check the contents of the legal-notices for: ' + pod.name)
            pod.is_expected_legal_notices()

    def test_version(self):
        """Check the version"""

        representative_pod = TestAmsterMetadata.pods[0]
        representative_pod.is_expected_version()

    def test_pods_jdk(self):
        """Check the JDK for the pods"""

        logger.test_step('Check JDK version')
        for pod in TestAmsterMetadata.pods:
            logger.info('Check JDK version for ' + pod.name)
            pod.is_expected_jdk()

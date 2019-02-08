# Copyright (c) 2016-2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Verify the versions of ForgeRock Product in use.
"""

# Lib imports
import os
import pytest

# Framework imports
from utils import logger, kubectl, pod, idm_pod
from utils.idm_pod import IDMPod


class TestIDMMetadata(object):
    MANIFEST_FILEPATH = os.path.join(pod.Pod.test_root_directory(),'config', '6.5.0-manifest.txt')
    environment_properties = dict(os.environ)
    NAMESPACE= environment_properties.get('TESTS_NAMESPACE')
    pods = []

    @classmethod
    def setup_class(cls):
        """Populate the lists of pods"""

        logger.test_step('Get pods')

        podnames = kubectl.get_product_pod_names(TestIDMMetadata.NAMESPACE, IDMPod.PRODUCT_TYPE)
        assert len(podnames) > 0,  'There are no AM pods'
        for podname in podnames:
            TestIDMMetadata.pods.append(IDMPod(podname, TestIDMMetadata.MANIFEST_FILEPATH))

    def test_idm_version_info(self):
        """Check the AM and Amster versions match"""

        TestIDMMetadata.pods[0].is_expected_version()

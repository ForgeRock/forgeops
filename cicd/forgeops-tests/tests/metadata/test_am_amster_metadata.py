# Copyright (c) 2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Verify the versions of ForgeRock Product in use.
"""

# Lib imports
import pytest

# Framework imports
from utils import logger, kubectl, pod
from utils.am_pod import AMPod
from utils.amster_pod import AmsterPod


class TestAMAmsterMetadata(object):
    representative_am_pod = None
    representative_amster_pod = None


    @classmethod
    def setup_class(cls):

        logger.test_step('Get pods')
        am_podnames = kubectl.get_product_component_names(pod.Pod.NAMESPACE, AMPod.PRODUCT_TYPE)
        assert len(am_podnames) > 0,  'There are no AM pods'
        TestAMAmsterMetadata.representative_am_pod = AMPod(am_podnames[0])

        amster_podnames = kubectl.get_product_component_names(pod.Pod.NAMESPACE, AmsterPod.PRODUCT_TYPE)
        assert len(amster_podnames) > 0,  'There are no Amster pods'
        TestAMAmsterMetadata.representative_amster_pod = AmsterPod(amster_podnames[0])

    def test_am_amster_versions(self):
        """Check the AM and Amster versions match"""

        logger.test_step('Check AM and Amster versions match')
        am_version = TestAMAmsterMetadata.representative_am_pod.version()
        amster_version = TestAMAmsterMetadata.representative_amster_pod.version()

        assert (am_version['VERSION'] == amster_version['VERSION']), \
            'AM version [{am_version}] is not the same as Amster [{amster_version]'.format(
                am_version=am_version['VERSION'], amster_version=amster_version['VERSION'])
        assert (am_version['REVISION'] == amster_version['REVISION']), \
            'AM revision [{am_revision}] is not the same as Amster [{amster_revision]'.format(
                am_revision=am_version['REVISION'], amster_revision=amster_version['REVISION'])

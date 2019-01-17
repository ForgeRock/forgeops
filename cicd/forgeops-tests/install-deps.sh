#!/bin/bash
# Install dependencies for forgeops-tests if you are running tests from
# your local copy.
#
# Otherwise this will be taken care by docker image

pip3 install pytest
pip3 install allure-pytest
pip3 install pytest-html
pip3 install pytest-metadata
pip3 install requests

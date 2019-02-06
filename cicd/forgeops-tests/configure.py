#!/usr/bin/env python3
# Copyright (c) 2016-2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Customize the helm charts (change image tag, repository,...) and list of components to deploy
"""

# Python imports
import sys
import os
import shutil
import yaml
import re

TESTS_NAMESPACE = "smoke"
if "TESTS_NAMESPACE" in os.environ:
    TESTS_NAMESPACE = os.environ["TESTS_NAMESPACE"]

TESTS_DOMAIN = "forgeops.com"
if "TESTS_DOMAIN" in os.environ:
    TESTS_DOMAIN = os.environ["TESTS_DOMAIN"]

TESTS_IMAGE_TAG = "7.0.0-SNAPSHOT"
if "TESTS_IMAGE_TAG" in os.environ:
    TESTS_IMAGE_TAG = os.environ["TESTS_IMAGE_TAG"]

TESTS_DEPLOYMENT = "smoke-deployment"
if "TESTS_DEPLOYMENT" in os.environ:
    TESTS_DEPLOYMENT = os.environ["TESTS_DEPLOYMENT"]

TESTS_COMPONENTS = ""
if "TESTS_COMPONENTS" in os.environ:
    TESTS_COMPONENTS = os.environ["TESTS_COMPONENTS"]

IMAGE_BASE_URL = 'forgerock-docker-public.bintray.io/forgerock'
IMAGE_PULL_POLICY = 'Always'

OPENAM_HELM_SUBFOLDER = "openam"
OPENAM_IMAGE_NAME = "openam"
OPENAM_DEPENDENCIES = "configstore"

AMSTER_HELM_SUBFOLDER = "amster"
AMSTER_IMAGE_NAME = "amster"
AMSTER_DEPENDENCIES = ""

USERSTORE_HELM_SUBFOLDER = "ds"
USERSTORE_IMAGE_NAME = "ds-paas"
USERSTORE_DEPENDENCIES = ""

CTSSTORE_HELM_SUBFOLDER = "ds"
CTSSTORE_IMAGE_NAME = "ds-paas"
CTSSTORE_DEPENDENCIES = ""

CONFIGSTORE_HELM_SUBFOLDER = "ds"
CONFIGSTORE_IMAGE_NAME = "ds-paas"
CONFIGSTORE_DEPENDENCIES = ""

OPENIDM_HELM_SUBFOLDER = "openidm"
OPENIDM_IMAGE_NAME = "idm"
OPENIDM_DEPENDENCIES = "postgres-openidm"

OPENIG_HELM_SUBFOLDER = "openig"
OPENIG_IMAGE_NAME = "ig"
OPENIG_DEPENDENCIES = ""

if __name__ == "__main__":
    # root_dir : computed using relative position from this file
    current_dir = os.path.abspath(os.path.dirname(__file__))
    os.chdir(os.path.join(os.path.abspath(os.path.dirname(__file__)), '..', '..'))
    root_dir = os.getcwd()
    os.chdir(current_dir)

    helm_dir = os.path.join(root_dir, 'helm')
    config_dir = os.path.join(root_dir, 'samples', 'config', TESTS_DEPLOYMENT)
    env_file = os.path.join(config_dir, 'env.sh')

    if TESTS_COMPONENTS == "":
        env_components = ""

        # read content of env file to get default components list
        with open(env_file, 'r') as stream:
            for line in stream:
                if line.startswith('COMPONENTS='):
                    TESTS_COMPONENTS = re.sub(r'COMPONENTS=\((.*)\)', r'\g<1>', line.strip())
                    break
    else:
        env_components = "web frconfig"

    for component in TESTS_COMPONENTS.split(" "):
        if component in ['amster', 'openam', 'userstore', 'configstore', 'ctsstore', 'openidm', 'openig']:
            subfolder = eval('%s_HELM_SUBFOLDER' % component.upper())
            image = eval('%s_IMAGE_NAME' % component.upper())
            dependencies = eval('%s_DEPENDENCIES' % component.upper())

            values_yaml_file = os.path.join(helm_dir, subfolder, 'values.yaml')
            # restore original file
            if os.path.exists('%s.orig' % values_yaml_file):
                shutil.copy2('%s.orig' % values_yaml_file, values_yaml_file)
            # save file
            shutil.copy2(values_yaml_file, '%s.orig' % values_yaml_file)

            # read content of yaml file
            values_yaml_content = ""
            with open(values_yaml_file, 'r') as stream:
                try:
                    values_yaml_content = yaml.load(stream)
                except yaml.YAMLError as exc:
                    print(exc)

            # update values
            values_yaml_content['image']['repository'] = '%s/%s' % (IMAGE_BASE_URL, image)
            values_yaml_content['image']['tag'] = TESTS_IMAGE_TAG
            values_yaml_content['image']['pullPolicy'] = IMAGE_PULL_POLICY

            # save new content
            with open(values_yaml_file, 'w') as stream:
                try:
                    yaml.dump(values_yaml_content, stream, default_flow_style=False)
                except yaml.YAMLError as exc:
                    print(exc)

            env_components = "%s %s %s" % (env_components, dependencies, component)
        else:
            env_components = "%s %s" % (env_components, component)

    print("The following components will be installed: %s" % env_components)

    # restore original file
    if os.path.exists('%s.orig' % env_file):
        shutil.copy2('%s.orig' % env_file, env_file)
    # save file
    shutil.copy2(env_file, '%s.orig' % env_file)

    # read content of env file
    env_content = ""
    with open(env_file, 'r') as stream:
        env_content = stream.read()

    # update values
    env_content = re.sub(r'NAMESPACE=.*', 'NAMESPACE=%s' % TESTS_NAMESPACE, env_content)
    env_content = re.sub(r'DOMAIN=.*', 'DOMAIN="%s"' % TESTS_DOMAIN, env_content)
    env_content = re.sub(r'COMPONENTS=.*', 'COMPONENTS=(%s)' % env_components, env_content)

    # save new content
    with open(env_file, 'w') as stream:
        try:
            stream.write(env_content)
        except yaml.YAMLError as exc:
            print(exc)

    print("TO DEPLOY        : ../../bin/deploy.sh -n %s ../../samples/config/%s" % (TESTS_NAMESPACE, TESTS_DEPLOYMENT))
    print("TO RUN AM TESTS  : ./forgeops-tests.py tests/postcommit/am")
    print("TO RUN DJ TESTS  : ./forgeops-tests.py tests/postcommit/ds")
    print("TO RUN IDM TESTS : ./forgeops-tests.py tests/postcommit/idm")
    print("TO RUN IG TESTS  : ./forgeops-tests.py tests/postcommit/ig")


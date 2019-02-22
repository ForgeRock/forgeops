#!/usr/bin/env python3
# Copyright (c) 2019 ForgeRock AS. Use of this source code is subject to the
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

TESTS_USE_EMPTY_CONFIG = "False"
if "TESTS_USE_EMPTY_CONFIG" in os.environ:
    TESTS_USE_EMPTY_CONFIG = os.environ["TESTS_USE_EMPTY_CONFIG"]

IMAGE_BASE_URL = 'forgerock-docker-public.bintray.io/forgerock'
IMAGE_PULL_POLICY = 'Always'

OPENAM_HELM_SUBFOLDER = "openam"
OPENAM_IMAGE_NAME = "am"
OPENAM_DEPENDENCIES = "configstore"

AMSTER_HELM_SUBFOLDER = "amster"
AMSTER_IMAGE_NAME = "amster"
AMSTER_DEPENDENCIES = ""

USERSTORE_HELM_SUBFOLDER = "ds"
USERSTORE_IMAGE_NAME = "ds"
USERSTORE_DEPENDENCIES = ""

CTSSTORE_HELM_SUBFOLDER = "ds"
CTSSTORE_IMAGE_NAME = "ds"
CTSSTORE_DEPENDENCIES = ""

CONFIGSTORE_HELM_SUBFOLDER = "ds"
CONFIGSTORE_IMAGE_NAME = "ds"
CONFIGSTORE_DEPENDENCIES = ""

OPENIDM_HELM_SUBFOLDER = "openidm"
OPENIDM_IMAGE_NAME = "idm"
OPENIDM_DEPENDENCIES = "postgres-openidm"

OPENIG_HELM_SUBFOLDER = "openig"
OPENIG_IMAGE_NAME = "ig"
OPENIG_DEPENDENCIES = ""

if __name__ == "__main__":
    # root_dir : computed using relative position from this file
    current_dir = os.getcwd()
    root_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))

    src_config_dir = os.path.join(root_dir, 'samples', 'config', TESTS_DEPLOYMENT)
    if not os.path.exists(src_config_dir):
        print("Config directory '%s' does not exist and is mandatory to customize deployment" % src_config_dir)
        sys.exit(1)

    tmp_dir = os.path.join(current_dir, 'tmp')
    config_dir = os.path.join(tmp_dir, TESTS_DEPLOYMENT)
    env_file = os.path.join(config_dir, 'env.sh')

    # Copy the config directory to avoid change the file under git
    if not os.path.exists(tmp_dir):
        os.makedirs(tmp_dir)
    if os.path.exists(config_dir):
        shutil.rmtree(config_dir)
    shutil.copytree(src_config_dir, config_dir)

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

            values_yaml_file = os.path.join(config_dir, '%s.yaml' % component)

            # read content of yaml file
            values_yaml_content = dict()
            with open(values_yaml_file, 'r') as stream:
                try:
                    values_yaml_content = yaml.load(stream)
                except yaml.YAMLError as exc:
                    print(exc)
            if values_yaml_content is None:
                values_yaml_content = dict()

            # update values
            image_dict = dict()
            image_dict['repository'] = '%s/%s' % (IMAGE_BASE_URL, image)
            image_dict['tag'] = TESTS_IMAGE_TAG
            image_dict['pullPolicy'] = IMAGE_PULL_POLICY
            values_yaml_content['image'] = image_dict

            if TESTS_USE_EMPTY_CONFIG == "True":
                config_dict = dict()
                config_dict['claim'] = 'frconfig'
                config_dict['importPath'] = '/git/config/6.5/default/am/empty-import'
                values_yaml_content['config'] = config_dict

            # save new content
            with open(values_yaml_file, 'w') as stream:
                try:
                    yaml.dump(values_yaml_content, stream, default_flow_style=False)
                except yaml.YAMLError as exc:
                    print(exc)

            if dependencies not in env_components:
                env_components = "%s %s" % (env_components, dependencies)
        env_components = "%s %s" % (env_components, component)

    print("The following components will be installed: %s" % env_components)

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
        stream.write(env_content)

    if "JOB_NAME" not in os.environ:
        # Only print these information whne running outside Jenkins
        print("TO DEPLOY        : ../../bin/deploy.sh -n %s %s" % (TESTS_NAMESPACE, config_dir))
        print("TO RUN AM TESTS  : ./forgeops-tests.py tests/postcommit/am")
        print("TO RUN DJ TESTS  : ./forgeops-tests.py tests/postcommit/ds")
        print("TO RUN IDM TESTS : ./forgeops-tests.py tests/postcommit/idm")
        print("TO RUN IG TESTS  : ./forgeops-tests.py tests/postcommit/ig")

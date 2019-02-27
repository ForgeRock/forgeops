# Copyright 2019 ForgeRock AS. All Rights Reserved
# Use of this code requires a commercial software license with ForgeRock AS. or with one of its affiliates.
# All use shall be exclusively subject to such license between the licensee and ForgeRock AS.

# Lib imports
import os
from requests import get, post
from utils import logger, rest
from ProductConfig import IDMConfig, AMConfig, IGConfig, DSConfig


def pytest_configure(config):
    root_dir = os.path.abspath(os.path.join(os.path.dirname( __file__ ), '..'))

    properties = get_tests_properties()
    if 'TESTS_NAMESPACE' in properties:
        config._metadata['TESTS_NAMESPACE'] = properties['TESTS_NAMESPACE']
    else:
        config._metadata['TESTS_NAMESPACE'] = 'smoke'
    if 'TESTS_DOMAIN' in properties:
        config._metadata['TESTS_DOMAIN'] = properties['TESTS_DOMAIN']
    else:
        config._metadata['TESTS_DOMAIN'] = 'forgeops.com'

    if 'TESTS_COMPONENTS' in properties:
        config._metadata['TESTS_COMPONENTS'] = properties['TESTS_COMPONENTS']
        version_info = get_version_info(properties['TESTS_COMPONENTS'])
        for key, value in version_info.items():
            config._metadata[key] = value
            properties[key] = value

    report_path = 'reports'
    if not os.path.exists(report_path):
        os.makedirs(report_path)

    set_allure_environment_props(os.path.join(root_dir, report_path, 'allure-files/environment.properties'),
                                 properties)


def get_version_info(components):
    components_list = components.split()
    component_version_info = {}
    for component in components_list:
        if component == "openidm":
            component_version_info['OPENIDM_VERSION'] = get_idm_version_info()
        if component == "openam":
            component_version_info['OPENAM_VERSION'] = get_am_version_info()

    return component_version_info


def get_idm_version_info():
    idm_cfg = IDMConfig()

    logger.info("Get software version of the OpenIDM instance")
    headers = idm_cfg.get_admin_headers({'Content-Type': 'application/json'})
    response = get(verify=idm_cfg.ssl_verify, url=idm_cfg.idm_url + '/info/version', headers=headers)
    rest.check_http_status(http_result=response, expected_status=200)
    version_info = "{} (build: {}, revision: {})".format(response.json()['productVersion'],
                                                         response.json()['productBuildDate'],
                                                         response.json()['productRevision'])
    return version_info


def get_am_version_info():
    am_cfg = AMConfig()

    logger.info("Get software version of the OpenAM instance")
    headers = {'X-OpenAM-Username': 'amadmin', 'X-OpenAM-Password': 'password',
               'Content-Type': 'application/json', 'Accept-API-Version': 'resource=2.0, protocol=1.0'}

    response = post(verify=am_cfg.ssl_verify, url=am_cfg.rest_authn_url, headers=headers)
    rest.check_http_status(http_result=response, expected_status=200)
    admin_token = response.json()['tokenId']

    logger.info('Get AM version')
    headers = {'Content-Type': 'application/json', 'Accept-API-Version': 'resource=1.0',
               'iplanetdirectorypro': admin_token}
    response = get(verify=am_cfg.ssl_verify, url=am_cfg.am_url + '/json/serverinfo/version', headers=headers)
    rest.check_http_status(http_result=response, expected_status=200)
    version_info = "{} (build: {}, revision: {})".format(response.json()['version'],
                                                                   response.json()['date'],
                                                                   response.json()['revision'])
    return version_info


def get_tests_properties():
    """
    :return: dictionary containing the environment properties starting with TESTS_
    """

    # Get os environment properties as dictionary
    environment_properties = dict(os.environ)

    # Get properties that start with TESTS_ from environment.properties
    tests_properties = {}
    for key, value in environment_properties.items():
        if key.startswith("TESTS_"):
            tests_properties[key] = environment_properties[key]
    return tests_properties


def set_allure_environment_props(filename, properties):
    """
    :param filename: file to write properties to
    :param properties: dictionary containing the properties
    """

    # Check path structure for environment.properties exists otherwise create it
    if not os.path.exists(os.path.dirname(filename)):
        os.makedirs(os.path.dirname(filename))

    # Write properties to environment.properties file
    with open(filename, 'w') as file:
        for key, value in properties.items():
            file.write('{}={}\n'.format(key, value))

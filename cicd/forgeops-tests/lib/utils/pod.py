# Copyright (c) 2016-2019 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file

"""
Metadata related to kubernetes pods
"""
# Lib imports
import os
from prettytable import PrettyTable

# Framework imports
from utils import logger, kubectl


class Pod(object):

    environment_properties = dict(os.environ)
    NAMESPACE = environment_properties.get('TESTS_NAMESPACE')

    def __init__(self, product_type, name):
        """
        :param product_type: ForgeRock Platform product type
        :param name: Pod name
        """

        assert isinstance(product_type, str), 'Invalid product type type %s' % type(product_type)
        assert isinstance(name, str), 'Invalid name type %s' % type(name)

        self._product_type = product_type
        self._name = name

    @property
    def product_type(self):
        return self._product_type

    @property
    def name(self):
        return self._name

    @staticmethod
    def get_metadata_of_interest(title, description, metadata, get_attributes):
        """
        Obtain a dictionary containing attributes of interest.
        :param title: The title for the attributes.
        :param description: Description of the data
        :param metadata: Pod metadata
        :param get_attributes: Keys ot attributes that are required in the dictionary.
        :return: Metadata dictionary indexed by the attribute keys.
        """
        assert isinstance(title, str), 'Invalid title type %s' % type(title)
        assert isinstance(description, str), 'Invalid descripton type %s' % type(description)
        assert isinstance(metadata, list), 'Invalid metadata type %s' % type(metadata)
        assert isinstance(get_attributes, set), 'Invalid get attributes type %s' % type(get_attributes)

        metadata_of_interest = {'TITLE': title,
                                'DESCRIPTION': description}

        found_keys = set()
        for line in metadata:
            logger.debug('Reading metdata: ' + line)
            for info_key in get_attributes:
                if line.strip().startswith(info_key):
                    info = line.strip().split(info_key)
                    if len(info) == 2:
                        metadata_of_interest[info_key] = info[1].strip(' :=')
                        found_keys.add(info_key)
                        logger.debug('Found ' + info_key)
                        continue
        assert found_keys == get_attributes

        return metadata_of_interest

    @staticmethod
    def print_table(table_data):
        """
        Print a table of version metadata.
        :param table_data: Dictionary of data to be printed
        """

        assert isinstance(table_data, dict), 'Invalid title type %s' % type(table_data)

        table = PrettyTable([table_data['TITLE'], table_data['DESCRIPTION']])
        for key, value in table_data.items():
            if key in ['TITLE', 'DESCRIPTION']:
                continue
            table.add_row([key, value])
        logger.info(table)

    def is_expected_version(self):
        """
        Check if the version is as expected.
        """

        assert False, 'Not implemented, please override in subclass'

    def is_expected_legal_notices(self):
        """
        Check if the representative license file is present on the pod, otherwise assert.
        """

        file_of_interest = 'Forgerock_License.txt'
        stdout, ignored = kubectl.exec(
            Pod.NAMESPACE, [self.name, '-c', self.product_type, '--', 'find', '.', '-name', file_of_interest])
        file_path = stdout[0].strip()
        logger.debug('Found legal notice: ' + file_path)
        assert (file_path.endswith('legal-notices/' + file_of_interest)), 'Unable to find ' + file_of_interest

    def is_expected_versioned_commons_jar(self, lib_path, jar_name):
        """
        Check if the commons version is as expected.
        :param lib_path: Path to jar library.
        :param jar_name: Jar file to check.
        """
        logger.debug('Check commons version for %s*.jar' % jar_name)
        stdout, ignored = kubectl.exec(
            Pod.NAMESPACE, [self.name, '-c', self.product_type, '--', 'find', lib_path, '-name', jar_name + '-*.jar'])
        config_filepath = stdout[0]  # first line of output
        start = config_filepath.find(jar_name)
        end = config_filepath.find('.jar')
        commons_version = config_filepath[start + len(jar_name) + 1: end]
        metadata = {'TITLE': "Commons",
                    'DESCRIPTION': self.name,
                    'VERSION': commons_version,
                    'FILE': config_filepath}
        Pod.print_table(metadata)

    def is_expected_jdk(self, attributes_of_interest):
        """
        Check if Java is as expected.
        :param attributes_of_interest: Set of attribute keys to check.
        """

        assert isinstance(attributes_of_interest, set),\
            'Invalid attributes of interest type %s' % type(attributes_of_interest)

        logger.debug('Check Jaa version for ' + self.name)
        ignored, metadata = kubectl.exec(
            Pod.NAMESPACE, [self.name, '-c', self.product_type, '--', 'java', '-version'])  # TODO: why stderr
        java_metadata = Pod.get_metadata_of_interest('Java', self.name, metadata, attributes_of_interest)
        Pod.print_table(java_metadata)

    def is_expected_os(self, attributes_of_interest):
        """
        Check if operating system is as expected.
        :param attributes_of_interest: Set of attribute keys to check.
        """

        assert isinstance(attributes_of_interest, set),\
            'Invalid attributes of interest type %s' % type(attributes_of_interest)

        logger.debug('Check OS version for ' + self.name)
        metadata, ignored = kubectl.exec(
            Pod.NAMESPACE, [self.name, '-c', self.product_type, '--', 'cat', '/etc/os-release'])
        os_metadata = Pod.get_metadata_of_interest('OS', self.name, metadata, attributes_of_interest)
        Pod.print_table(os_metadata)

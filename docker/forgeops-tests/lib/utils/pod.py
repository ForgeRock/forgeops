# Copyright (c) 2019 ForgeRock AS. Use of this source code is subject to the
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

        metadata_of_interest = {'TITLE': title,
                                'DESCRIPTION': description}

        found_keys = set()
        for line in metadata:
            logger.debug('Reading metdata: {data}'.format(data=line))
            for info_key in get_attributes:
                if line.strip().startswith(info_key):
                    info = line.strip().split(info_key)
                    if len(info) == 2:
                        metadata_of_interest[info_key] = info[1].strip(' :=')
                        found_keys.add(info_key)
                        logger.debug('Found {key}'.format(key=info_key))
                        continue
        assert found_keys == get_attributes

        return metadata_of_interest

    @staticmethod
    def print_table(table_data):
        """
        Print a table of version metadata.
        :param table_data: Dictionary of data to be printed
        """

        table = PrettyTable([table_data['TITLE'], table_data['DESCRIPTION']])
        for key, value in table_data.items():
            if key in ['TITLE', 'DESCRIPTION']:
                continue
            table.add_row([key, value])
        logger.info(table)

    def version(self):
        """
        Return the product version information.
        :return: Dictionary
        """

        assert False, 'Not implemented, please override in subclass'

    def log_version(self):
        """Report the product version."""

        logger.debug('Check version for {name}'.format(name=self.name))
        Pod.print_table(self.version())

    def are_legal_notices_present(self):
        """
        Check if the representative license file is present on the pod, otherwise assert.
        """

        file_of_interest = 'Forgerock_License.txt'
        stdout, ignored = kubectl.exec(
            Pod.NAMESPACE, [self.name, '-c', self.product_type, '--', 'find', '.', '-name', file_of_interest])
        file_path = stdout[0].strip()
        logger.debug('Found legal notice: {file}'.format(file=file_path))
        assert (file_path.endswith('legal-notices/{file}'.format(file=file_of_interest))),\
            'Unable to find {file_of_interest}'.format(file_of_interest=file_of_interest)

    def log_versioned_commons_jar(self, lib_path, jar_name):
        """
        Report version of commons; obtained from the name of a sample commons .jar.
        :param lib_path: Path to jar library.
        :param jar_name: Jar file to check.
        """
        logger.debug('Check commons version for {name}*.jar'.format(name=jar_name))
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

    def log_jdk(self, attributes_of_interest):
        """
        Report Java versions for pod.
        :param attributes_of_interest: Set of attribute keys to check.
        """

        logger.debug('Check Jaa version for {name}'.format(name=self.name))
        ignored, metadata = kubectl.exec(
            Pod.NAMESPACE, [self.name, '-c', self.product_type, '--', 'java', '-version'])  # TODO: why stderr
        java_metadata = Pod.get_metadata_of_interest('Java', self.name, metadata, attributes_of_interest)
        Pod.print_table(java_metadata)

    def log_os(self, attributes_of_interest):
        """
        Report Operating System on the pod.
        :param attributes_of_interest: Set of attribute keys to check.
        """

        logger.debug('Check OS version for {name}'.format(name=self.name))
        metadata, ignored = kubectl.exec(
            Pod.NAMESPACE, [self.name, '-c', self.product_type, '--', 'cat', '/etc/os-release'])
        os_metadata = Pod.get_metadata_of_interest('OS', self.name, metadata, attributes_of_interest)
        Pod.print_table(os_metadata)

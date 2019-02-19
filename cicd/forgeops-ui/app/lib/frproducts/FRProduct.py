import os
from yaml import dump, load
from app.lib.log import get_logger


class FRProduct(object):
    """
    Base class for all products/helm charts
    """
    def __init__(self, chart_name, instance_name):
        self.dependency_charts = []
        self.values = {}
        self.chart_name = chart_name
        self.instance_name = instance_name
        self.namespace = None
        self.domain = None
        self.base_folder = os.path.join('/tmp/forgeops/helm/', self.chart_name)
        self.custom_yaml_path = os.path.join('/tmp/', self.instance_name + '.yaml')
        self.url = None
        self.livecheck_url = None
        self.timeout = 600
        self.logger = get_logger(self.__class__.__name__)

    def set_namespace(self, namespace):
        """
        Sets a product namespace
        :param namespace: Namespace for product to deploy in
        """
        self.namespace = namespace

    def set_domain(self, domain):
        """
        Sets a product domain
        :param domain: Domain
        """
        self.domain = '.' + domain

    def set_livecheck_url(self):
        pass

    def dump_yaml(self):
        """
        Write values into file we will use for overriding default values
        """
        with open(self.custom_yaml_path, 'w') as f:
            dump(self.values, f, default_flow_style=False)

    def load_yaml(self):
        """
        Loads default product yaml and parses it to dict structure
        :return: Dictionary with product values
        """
        with open(os.path.join(self.base_folder, 'values.yaml'), 'r') as f:
            data = f.read()

        return load(data)

    def set_values(self, vals):
        """
        Set values for product.
        :param vals: Yaml file with override values
        """
        self.values = vals

    def livecheck(self):
        return False


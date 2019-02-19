import json

from git import Repo
import shutil
import os

from yaml import load

from app.lib.log import get_logger
from logging import INFO

product_to_chart_map = {
    'am': 'openam',
    'ig': 'openig',
    'idm': 'openidm',
    'postgres-idm': 'postgres-openidm',
    'userstore': 'userstore',
    'configstore': 'configstore',
    'amster': 'amster',
    'ctsstore': 'ctsstore'
}


class Forgeops(object):
    """
    Base class to handle forgeops repositories
    (Forgeops & forgeops-init)
    """
    def __init__(self):
        self.repo = 'https://github.com/ForgeRock/forgeops'
        self.config_repo = 'https://github.com/ForgeRock/forgeops-init'
        self.repo_path = '/tmp/forgeops'
        self.config_repo_path = '/tmp/forgeops-init'
        self.branch = 'master'
        self.logger = get_logger(self.__class__.__name__)
        self.repo_init()
        self.sample_configs = {
            'smoke': os.path.join(self.repo_path, 'samples/config/smoke-deployment/'),
            's-cluster': os.path.join(self.repo_path, 'samples/config/prod/s-cluster/'),
            'm-cluster': os.path.join(self.repo_path, 'samples/config/prod/m-cluster/'),
            'l-cluster': os.path.join(self.repo_path, 'samples/config/prod/l-cluster/')
        }

    def repo_init(self):
        """
        Init all repositories needed for forgeops.
        Can be used to update repositories to clean state as well
        """
        self.logger.log(INFO, 'Checking repo clone paths')
        if os.path.exists(self.config_repo_path):
            self.logger.log(INFO, 'Config repo folder exists. Deleting')
            shutil.rmtree(self.config_repo_path)
        if os.path.exists(self.repo_path):
            self.logger.log(INFO, 'Forgeops repo folder exists. Deleting')
            shutil.rmtree(self.repo_path)

        # Init git repos
        self.logger.log(INFO, 'Cloning ' + self.repo)
        Repo.clone_from(self.repo, self.repo_path, branch=self.branch)

        self.logger.log(INFO, 'Cloning ' + self.config_repo)
        Repo.clone_from(self.config_repo, self.config_repo_path, branch=self.branch)

    def set_default_repo(self):
        self.repo = 'https://github.com/ForgeRock/forgeops'
        self.config_repo = 'https://github.com/ForgeRock/forgeops-init'

    def set_custom_repo(self, repo_name, repo_branch):
        self.repo = repo_name
        self.branch = repo_branch
        self.repo_init()

    def get_current_repo(self):
        return {'repo': self.repo, 'branch': self.branch}

    # Config and sample ops

    def convert_sample_folder(self, path):
        if not os.path.isdir(path):
            raise NotADirectoryError('Provided path to samples is not directory or does not exists.')
        output = {
            "products": {},
            "global": {
                'domain': '.example.com',
                'namespace': 'example'
            },
            "ignore": []
        }

        # Vals from custom.yaml
        # Check if sample have common.yaml file
        common_yaml_file = os.path.join(path, 'common.yaml')
        if os.path.isfile(common_yaml_file):
            with open(common_yaml_file, 'r') as f:
                content = load(f)
                print(content)
            if 'domain' in content.keys():
                output['global']['domain'] = content['domain']

        # Crawl for each product in target folder and add values to output
        for key in product_to_chart_map:
            filepath = os.path.join(path, product_to_chart_map[key] + '.yaml')
            if not os.path.isfile(filepath):
                output['ignore'].append(key)
            else:
                with open(filepath, 'r') as f:
                    loaded_conf = load(f)
                    output['products'][key] = loaded_conf

        frconfig_path = os.path.join(path, 'frconfig.yaml')
        if not os.path.isfile(frconfig_path):
            self.logger.log(INFO, 'frconfig.yaml not found in directory, will use default values')
        else:
            with open(frconfig_path, 'r') as f:
                frcfg = load(f)
                output['global']['git_config_repo'] = frcfg['git']['repo']
                output['global']['git_config_repo_branch'] = frcfg['git']['branch']
        return output

    def get_config(self, config_name):
        if config_name not in self.sample_configs.keys():
            return '{"error": "Wrong config name"}'
        return json.dumps(self.convert_sample_folder(self.sample_configs[config_name]))

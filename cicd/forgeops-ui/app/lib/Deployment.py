import json
import os
import subprocess


from app.lib.frproducts.Web import Web
from app.lib.frproducts.IDMPostgres import IDMPostgres
from app.lib.frproducts.FRConfig import FRConfig
from app.lib.frproducts.AM import AM
from app.lib.frproducts.IDM import IDM
from app.lib.frproducts.IG import IG
from app.lib.frproducts.DS import DS
from app.lib.frproducts.Amster import Amster
from app.lib.ClusterController import ClusterController
from app.lib.Forgeops import Forgeops


# Deployment statues
NOT_DEPLOYED = 'not_deployed'
ERROR = 'error'
DEPLOYING = 'deploying'
DEPLOYED = 'deployed'
REMOVING = 'removing'

# Test statuses
NOT_RUNNING = 'not-running'
RUNNING = 'running'
FINISHED = 'finished'


class Deployment(object):
    """
    Deployment object class. Holds information about deployment and all related information. Provides a way
    how to deploy products into cluster. Additional stuff:
     - deploy
     - remove deployment
     - get deployment/service/ingress/pod info
     - get logs from pods
     - provide a way to modify deployment(scaling, etc...)
    """
    forgeops: Forgeops
    cluster: ClusterController

    def __init__(self, forgeops, cluster):
        self.product_list = {}
        self.forgeops = forgeops
        self.cluster = cluster
        self.product_list = {
            'am': AM(instance_name='am'),
            'amster': Amster(instance_name='amster'),
            'idm': IDM(instance_name='idm'),
            'postgres-idm': IDMPostgres(instance_name='postgres-idm'),
            'ig': IG(instance_name='ig'),
            'userstore': DS(instance_name='userstore'),
            'configstore': DS(instance_name='configstore'),
            'ctsstore': DS(instance_name='ctsstore')
        }

        self.current_config = {
            "products": {},
            "global": {},
            "ignore": []
        }

        self.default_config = {
            "products": {},
            "global": {
                "domain": "example.com",
                "namespace": "changeme",
                "git_config_repo": "https://github.com/ForgeRock/forgeops-init.git",
                "git_config_repo_branch": "master",
            },
            "ignore": []

        }

        self.product_pod_mapping = {

        }

        for product in self.product_list:
            self.default_config['products'][product] = self.product_list[product].load_yaml()

        self.status = NOT_DEPLOYED
        # First run. If not configured for the first time, we can't deploy
        self.namespace = None
        self.domain = None
        self.configured = False

        self.test_path = os.path.join(self.forgeops.repo_path, 'cicd', 'forgeops-tests')
        self.test_status = NOT_RUNNING

        self.base_tests_path = os.path.join(self.forgeops.repo_path, 'cicd', 'forgeops-tests')

    # ================ CONFIG ======================

    def reset_environment(self):
        """
        Resets whole environment, makes sure nothing is deployed in target namespace
        """
        # TODO - Implement
        pass

    def set_config(self, product_config):
        """
        Parses a json with product configuration, sets which products will be deployed.
        :param product_config: JSON with product configs
        """
        pc = json.loads(product_config)
        self.current_config['ignore'] = pc['ignore']
        self.current_config['products'] = pc['products']
        self.current_config['global'] = pc['global']
        self.namespace = self.current_config['global']['namespace']
        self.domain = self.current_config['global']['domain']
        self.cluster.set_namespace(self.namespace)

        for product in self.product_list.keys():
            self.product_list[product].set_namespace(self.namespace)
            self.product_list[product].set_domain(self.domain)
            self.product_list[product].set_livecheck_url()

        self.configured = True

    def get_default_config(self):
        """
        Compile default schemas for products
        :return: JSON string with product default config values
        """
        return json.dumps(self.default_config)

    def get_current_config(self):
        """
        Returns current configs for products
        :return: JSON string with product current config values
        """
        return json.dumps(self.current_config)

    # ================== EXECUTION ======================

    def deploy_products(self):
        """
        Trigger product deployment
        Check ignore list and then
        """
        if not self.configured:
            return '{"error": "Products not configured. Submit configuration first"}'
        if self.status == NOT_DEPLOYED:

            if self.current_config['products'].keys().__len__() == 0:
                return json.dumps({'error': 'No products selected for deployment'})

            self.status = DEPLOYING
            # Setup frconfig and parse correct values
            tbd = []
            frconfig = FRConfig(instance_name='frconfig')
            frconfig_values = {
                'git': {
                    'repo': self.current_config['global']['git_config_repo'],
                    'branch': self.current_config['global']['git_config_repo_branch']
                }
            }
            frconfig.set_values(frconfig_values)
            frconfig.dump_yaml()

            if 'ig' in self.current_config['products'].keys():
                web = Web(instance_name='web')
                web_config = {
                    'domain': self.domain
                }
                web.set_values(web_config)
                web.dump_yaml()
                tbd.append(web)

            tbd.append(frconfig)

            # Add configs and dump config values into yamls
            # Add only products which are not set to ignore
            for key in self.product_list:
                if key not in self.current_config['ignore']:
                    # DS store type instance name setting
                    if key in ['userstore', 'configstore', 'ctsstore']:
                        self.current_config['products'][key]['instance'] = key

                    self.product_list[key].set_values(self.current_config['products'][key])
                    self.product_list[key].dump_yaml()

                    tbd.append(self.product_list[key])

            self.cluster.set_namespace(self.current_config['global']['namespace'])
            out = ""
            for product in tbd:
                out = out + str(self.cluster.deploy_helm_chart(path=product.base_folder,
                                                               chart_name=product.instance_name,
                                                               custom_yaml=product.custom_yaml_path))
            self.status = DEPLOYED
            return json.dumps({"status": "Products deployment initiated"})

        else:
            return '{"error": "Deployment is already deployed or being deployed"}'

    def remove_deployment(self):
        """
        Completely remove whole deployment. Keeps namespace and
        :return:
        """
        if self.status == DEPLOYED:
            self.status = REMOVING
            charts = self.cluster.get_helm_charts()
            for chart in charts:
                self.cluster.delete_helm_chart(chart)
            self.cluster.kubectl(['delete', 'pvc', '--all'])
            self.status = NOT_DEPLOYED
            self.test_status = NOT_RUNNING
            return "Success"
        elif self.status == REMOVING:
            return "Removal in progress"
        else:
            return "Can't remove deployment. Products are not deployed"

    def get_deployment_info(self):
        """
        Get complete deployment info and basic product status
        :return: JSON with product status and deployment information
        """
        if self.status == NOT_DEPLOYED:
            return json.dumps({"status": "NOT DEPLOYED"})

        depl_info = {
            'namespace': self.namespace,
            'domain': self.domain,
            'status': self.status,
            'endpoints': {}
        }
        if self.status == DEPLOYED:
            depl_info['endpoints'] = self.get_product_endpoints()

        return json.dumps(depl_info)

    def get_deployment_endpoints(self):
        return json.dumps({'endpoints': self.get_product_endpoints()})

    def get_product_pod_mapping(self):
        self.update_product_mapping()
        pod_mapping = {'mappings': {}}
        for product in self.current_config['products'].keys():
            if product not in self.current_config['ignore']:
                pod_mapping['mappings'][product] = self.product_pod_mapping[product]
        return json.dumps(pod_mapping)

    def get_product_config_livecheck(self, product):
        """
        Some products (AM/Amster, IDM, IG) have live-checks for configs
        :param product: Product name
        :return: Status(READY/NOT_READY)
        """
        if product not in self.product_list.keys():
            return '{"error": "Wrong product"}'
        else:
            if product in ['userstore', 'configstore', 'ctsstore', 'postgres-idm']:
                return '{"status": "This product does not have config livecheck"}'

            elif product in ['amster']:
                if 'amster' not in self.product_pod_mapping.keys():
                    self.update_product_mapping()
                log = self.cluster.kubectl(['logs', self.product_pod_mapping['amster'][0], 'amster'])
                if 'Configuration script finished' in log:
                    return json.dumps({'status': 'READY'})
                else:
                    return json.dumps({'status': 'NOT_READY'})
            elif self.product_list[product].livecheck():
                return '{"status": "READY"}'
            else:
                return '{"status": "NOT_READY"}'

    def get_pod_status(self, pod_name):
        """
        Get's a pod status (running/initializing/terminating)
        :param pod_name: Pod name
        :return: Pod status in JSON
        """
        out = self.cluster.kubectl(['get', 'pod', pod_name, "-o", "jsonpath={.status.phase}"])
        if out.__contains__('Not Found'):
            return json.dumps({"error": "Pod not found"})

        return json.dumps({"status": out})

    def get_product_endpoints(self):
        ret = {}
        for product in ['am', 'idm', 'ig']:
            if product not in self.current_config['ignore']:
                out = self.cluster.kubectl(
                    ["get", "ingress", "open" + product, "-o", "jsonpath={.spec.rules[*].host}"])
                ret[product] = 'https://' + out + '/' + product
        return ret

    # ================== TESTING ==========================

    def run_smoke_tests(self):
        """
        Execute smoke tests in case smoke test config is used for products
        """
        print("Trying to run the tests. Status is " + self.test_status)
        if self.status == DEPLOYED and self.test_status in [NOT_RUNNING, FINISHED]:
            print('Entering test run loop. changin status to running')
            self.test_status = RUNNING

            os.environ['TESTS_NAMESPACE'] = self.namespace
            os.environ['TESTS_DOMAIN'] = self.domain

            test_process = subprocess.Popen(['python3', 'forgeops-tests.py', 'tests/smoke'],
                                            stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=self.base_tests_path)
            out = test_process.communicate()
            print(out)
            print('Tests are done, setting status to finished')
            self.test_status = FINISHED
            return json.dumps({'status': 'OK'})
        else:
            return json.dumps({'error': 'Cannot run tests. Not deployed'})

    def get_smoke_test_status(self):
        """
        Return smoke test status
        :return: JSON with smoke test status
        """
        return json.dumps({'status': self.test_status})

    def get_latest_smoke_tests_results(self):
        """

        Gets a results of smoke tests.
        :return: JSON results of smoke tests.
        """
        if self.test_status == FINISHED:
            report_path = os.path.join(self.base_tests_path, 'reports', 'latest.html')
            with open(report_path, 'r') as report:
                content = report.read()
                return content
        else:
            return 'You need to run the tests first.'

    # ================= HELPER METHODS =====================
    def update_product_mapping(self):
        """
        Updates product mapping to pods
        """
        for product in self.current_config['products'].keys():
            if product in ['userstore', 'configstore', 'ctsstore']:
                pod_name = self.cluster.kubectl(['get', 'pod', '-l', 'instance=' + product, '-o',
                                                 'jsonpath=\'{..items[*].metadata.name}\''])
            elif product in ['amster']:
                pod_name = self.cluster.kubectl(['get', 'pod', '-l', 'component=' + product, '-o',
                                                 'jsonpath=\'{..items[*].metadata.name}\''])
            elif product in ['postgres-idm']:
                pod_name = self.cluster.kubectl(['get', 'pod', '-l', 'app=postgres-openidm', '-o',
                                                 'jsonpath=\'{..items[*].metadata.name}\''])
            else:
                pod_name = self.cluster.kubectl(['get', 'pod', '-l', 'app=open' + product, '-o',
                                                 'jsonpath=\'{..items[*].metadata.name}\''])

            pod_name = pod_name[1:-1]
            pod_name = pod_name.split(' ')
            self.product_pod_mapping[product] = pod_name

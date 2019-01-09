import boto3
import requests
import copy
import re
import datetime
import dateutil
import json
import os
import operator
import yaml
from aws_openshift_quickstart.logger import LogUtil


class InventoryConfig(object):
    """
    Class to hold all of the configuration related objects / methods
    Methods:
        - setup: Initial class setup.
        - populate_from_ansible_inventory: Populates the known_instances dict w/data from the ansible inventory.
        - _determine_region_name: Determines the region that the cluster is in.
        -
    """
    log = LogUtil.get_root_logger()
    initial_inventory = False
    scale = False
    id_to_ip_map = dict()
    ansible_host_cfg = dict()
    all_instances = dict()
    known_instances = dict()
    ansible_inventory_file = '/etc/ansible/hosts'
    ansible_playbook_wrapper = "/usr/share/ansible/openshift-ansible/scaleup_wrapper.yml"
    playbooks = dict()
    playbook_directory = "/usr/share/ansible/openshift-ansible/"
    pre_scaleup_playbook = "{}{}".format(playbook_directory, "pre_scaleup.yml")
    pre_scaledown_playbook = "{}{}".format(playbook_directory, "pre_scaledown.yml")
    post_scaleup_playbook = "{}{}".format(playbook_directory, "post_scaleup.yml")
    post_scaledown_playbook = "{}{}".format(playbook_directory, "post_scaledown.yml")
    inventory_categories = {
        "master": ["masters", "new_masters"],
        "etcd": ["etcd", "new_etcd"],
        "node": ["nodes", "new_nodes"],
        "glusterfs": ["glusterfs", "new_glusterfs"],
        "provision": ["provision_in_progress"]
    }
    inventory_node_skel = {
        "master": [],
        "etcd": [],
        "node": [],
        "glusterfs": [],
        "provision": []
    }
    asg_node_skel = {
        "masters": [],
        "etcd": [],
        "nodes": [],
        "glusterfs": [],
        "provision": []
    }
    ansible_full_cfg = {}
    provisioning_hostdefs = {}
    inventory_nodes = copy.deepcopy(inventory_node_skel)
    inventory_nodes['ids'] = {}
    logical_names = {
        "OpenShiftEtcdASG": "etcd",
        "OpenShiftMasterASG": "masters",
        "OpenShiftNodeASG": "nodes",
        "OpenShiftGlusterASG": "glusterfs"
    }
    stack_id = None
    ec2 = None
    region_name = None
    instance_id = None
    ip_to_id_map = None

    @classmethod
    def setup(cls):
        """
        function to setup the variables initially (populate from inventory, etc)
        """
        cls.log.info("Setting up the InventoryConfig Class")
        if not cls.initial_inventory:
            cls.load_ansible_inventory_file()
        cls.region_name = cls._determine_region_name()
        cls.instance_id = cls._determine_local_instance_id()
        cls.ec2 = boto3.client('ec2', cls.region_name)
        for tag in cls._grab_local_tags():
            cls.log.debug(
                "Applying: [{}] / Value [{}] - as a method within the cluster.".format(tag['key'], tag['value']))
            setattr(cls, tag['key'], tag['value'])
        for instance in cls._grab_all_instances():
            iid = instance['InstanceId']
            cls.all_instances[iid] = instance
        cls.log.debug("The EC2 API Told me about these instances: {}".format(cls.all_instances.keys()))
        cls.log.info("InventoryConfig setup complete!")

    @classmethod
    def load_ansible_inventory_file(cls):
        cls.log.info("Loading ansible inventory file from on-disk...")
        try:
            with open(cls.ansible_inventory_file, 'r') as f:
                unparsed_document = f.read()
            parsed_document = yaml.load(unparsed_document)
        except Exception as e:
            raise e
        cls.ansible_full_cfg = parsed_document
        for (k, v) in parsed_document['OSEv3']['children'].iteritems():
            if len(v) == 0:
                continue
            cls.ansible_host_cfg[k] = v['hosts']
        cls.log.info("...Complete")

    @classmethod
    def write_ansible_inventory_file(cls, init=False):
        if not init:
            transformed_host_cfg = {k: {'hosts': v} for (k, v) in cls.ansible_host_cfg.iteritems()}
            cls.ansible_full_cfg['OSEv3']['children'].update(transformed_host_cfg)
        with open(cls.ansible_inventory_file, 'w') as f:
            f.write(yaml.dump(cls.ansible_full_cfg, default_flow_style=False))

    @classmethod
    def verify_required_sections_exist(cls, generate=False):
        """
        Verifies that the required sections exist within the Inventory.
        Ex: new_(masters|nodes|etcd), provision_in_progress
        """
        save_needed = False
        sections = [y for x in cls.inventory_categories.itervalues() for y in x]
        cls.log.info("I'm now verifying that all required sections are present in our runtime config...")
        if generate:
            cls.log.info("Accounting for initial inventory generation")
            compare_dict = cls.ansible_full_cfg['OSEv3']['children']
        else:
            compare_dict = cls.ansible_host_cfg
        for section in sections:
            if section not in compare_dict.keys():
                save_needed = True
                compare_dict[section] = {}
                cls.log.info(
                    "The section [{}] was not present in the Ansible Inventory. I'll add it...".format(section))
        cls.log.info("...Complete.")
        if save_needed:
            if generate:
                cls.ansible_full_cfg['OSEv3']['children'] = compare_dict
            else:
                cls.ansible_host_cfg = compare_dict

    @classmethod
    def populate_from_ansible_inventory(cls):
        """
        Populates the InventoryConfig class with data from the existing anisble inventory
        """
        cls.log.info("We're populating the runtime config from data within the Ansible Inventory")
        ac = cls.ansible_host_cfg
        ic = cls.inventory_categories
        for category, subcategory in ic.iteritems():
            cls.log.debug("Category: {}".format(category))
            if category == 'provision':
                continue
            for sc in subcategory:
                if sc != category:
                    cls.log.debug("\tSubcategory: [{}]/{}".format(category, sc))
                if len(ac[sc]) == 0:
                    cls.log.debug("\t No hosts within this subcategory. Moving on.")
                    continue
                for x, y in ac[sc].iteritems():
                    ip = x
                    try:
                        instance_id = y['instance_id']
                    except KeyError:
                        cls.log.info(
                            "Not able to associate an Instance ID with the Private DNS Entry: {}.".format(ip))
                        continue
                    cls.inventory_nodes[category].append(x)
                    cls.id_to_ip_map[instance_id] = x
                    cls.log.debug("I just added {} to the {} category".format(ip, category))
                    cls.known_instances[instance_id] = ip
                    cls.log.debug(
                        "The Instance ID {} has been tied to the Private DNS Entry: {}".format(instance_id, ip))

    @classmethod
    def _determine_region_name(cls):
        """
        Queryies the metadata service to determine the current Availability Zone.
        Extrapolates the region based on the AZ returned
        """
        resp = requests.get('http://169.254.169.254/latest/meta-data/placement/availability-zone')
        return resp.text[:-1]

    @classmethod
    def _determine_local_instance_id(cls):
        """
        Queries the metadata service to determine the local instance ID
        """
        resp = requests.get('http://169.254.169.254/latest/meta-data/instance-id')
        return resp.text

    @classmethod
    def _grab_all_instances(cls):
        """
        Generator around an ec2.describe_instances() call.
        Uses a filter to narrow down results.
        """
        filters = [{"Name": "tag:aws:cloudformation:stack-id", "Values": [InventoryConfig.stack_id]}]
        all_instances = cls.ec2.describe_instances(Filters=filters)['Reservations']

        i = 0
        while i < len(all_instances):
            j = 0
            while j < len(all_instances[i]['Instances']):
                yield all_instances[i]['Instances'][j]
                j += 1
            i += 1

    @classmethod
    def _grab_local_tags(cls):
        """
        Grabs the Cloudformation-set tags on the local instance.
        Dependent on the results of _determine_local_instance_id()
        """
        ec2 = boto3.resource('ec2', cls.region_name)
        local_instance = ec2.Instance(cls.instance_id)
        i = 0
        while i < len(local_instance.tags):
            if 'cloudformation' in local_instance.tags[i]['Key']:
                _k = local_instance.tags[i]['Key'].split(':')[2]
                yield {'key': _k.replace('-', '_'), 'value': local_instance.tags[i]['Value']}
            i += 1


class InventoryScaling(object):
    """
    Class to faciliate scaling activities in the Cluster's Auto Scaling Groups.
    """
    log = LogUtil.get_root_logger()
    nodes_to_add = copy.deepcopy(InventoryConfig.asg_node_skel)
    nodes_to_remove = copy.deepcopy(InventoryConfig.asg_node_skel)

    nodes_to_add['combined'] = []
    nodes_to_remove['combined'] = []
    ansible_results = {}
    _client = None

    @classmethod
    def wait_for_api(cls, instance_id_list=None):
        """
        Wait for instances in (class).nodes_to_add to show up in DescribeInstances API Calls. From there,
        we add them to the InventoryConfig.all_instances dictionary. This is necessary to allow the
        instances to be written to the Inventory config file
        """
        if not instance_id_list:
            instance_id_list = cls.nodes_to_add['combined']

        cls.log.info("[wait_for_api]: Waiting for the EC2 API to return new instances.")
        cls._client = boto3.client('ec2', InventoryConfig.region_name)
        waiter = cls._client.get_waiter('instance_exists')
        waiter.wait(InstanceIds=instance_id_list)

        for instance in cls._fetch_newly_launched_instances_from_api(cls.nodes_to_add['combined']):
            cls.log.debug("[{}] has been detected in the API.".format(instance))
            InventoryConfig.all_instances[instance['InstanceId']] = instance
        cls.log.info("[wait_for_api] Complete")

    @classmethod
    def _fetch_newly_launched_instances_from_api(cls, instance_id_list):
        """
        Generator.
        Fetches the newly-launched instances from the API.
        """
        filters = [{'Name': 'instance-id', 'Values': instance_id_list}]
        all_instances = cls._client.describe_instances(Filters=filters)['Reservations']
        i = 0
        while i < len(all_instances):
            j = 0
            while j < len(all_instances[i]['Instances']):
                yield all_instances[i]['Instances'][j]
                j += 1
            i += 1

    @classmethod
    def process_pipeline(cls):
        """
        ClassMethod that
            - prunes the config, removing nodes that are terminating.
            - adds nodes to the config that just launched
        """
        cls.log.info("We're processing the scaling pipeline")
        # Remove the nodes (from config) that are terminating.
        if cls.nodes_to_remove['combined']:
            cls.log.info("We have the following nodes to remove from the inventory:")
            cls.log.info("{}".format(cls.nodes_to_remove['combined']))
            cls.unsubscribe_nodes(cls.nodes_to_remove['combined'])
            for category in cls.nodes_to_remove.keys():
                if category == 'combined':
                    continue
                # cls.nodes_to_remove[category] is a list of instance IDs.
                cls.remove_node_from_section(cls.nodes_to_remove[category], category)
        else:
            cls.log.info("No nodes were found to remove from the inventory.")

        # Add the nodes that are launching.
        if cls.nodes_to_add['combined']:
            cls.log.info("We have the following nodes to add to the inventory:")
            cls.log.info("{}".format([x for x in cls.nodes_to_add['combined']]))
            for category in cls.nodes_to_add.keys():
                if category == 'combined':
                    continue
                cls.log.debug("Adding nodes {} to the {} category".format(cls.nodes_to_add[category], category))
                cls.add_nodes_to_section(cls.nodes_to_add[category], category)
            cls.log.info("Complete!")
        else:
            cls.log.info("No nodes were found to add to the inventory.")

    @classmethod
    def get_UUID(cls, nodeID):			
        cls.log.debug("UUID")
        region = requests.get('http://169.254.169.254/latest/meta-data/placement/availability-zone')
        region_name = region.text[:-1]
        ec2 = boto3.resource('ec2', region_name)
        ic = InventoryConfig
        cls.log.debug("[{}] nodeID".format(nodeID))
        ID = ic.ip_to_id_map[nodeID]
        cls.log.debug("[{}] ID".format(ID))
        local_instance = ec2.Instance(ID)
        i = 0
        while i < len(local_instance.tags):
            if 'UUID' in local_instance.tags[i]['Key']:
                yield {'key':local_instance.tags[i]['Key'], 'value': local_instance.tags[i]['Value']}
            i += 1

    @classmethod
    def unsubscribe_nodes(cls, node):
        """
        ClassMethod to unsubscribe nodes from RHEL subscription manager
        """
        cls.log.debug("Unsubscribing Nodes")
        unsubscribe_url = "Empty_URL"
        for node_key in node:
            cls.log.debug("[{}]".format(node_key))
            tags = cls.get_UUID(node_key)
            for tag in tags:
                cls.log.debug("[{}] / Value [{}] - Tag".format(tag['key'], tag['value']))
                unsubscribe_url = 'http://subscription.rhn.redhat.com/subscription/consumers/' + tag['value']
        cls.log.debug(unsubscribe_url)
        response = requests.delete(unsubscribe_url, verify='/etc/rhsm/ca/redhat-uep.pem')
        cls.log.debug("[{}]".format(response.text))

    @classmethod
    def add_nodes_to_section(cls, nodes, category, fluff=True, migrate=False):
        """
        Adds a node (private IP / private DNS Entry) to a config section
        """
        acfg = InventoryConfig.ansible_host_cfg
        ic = InventoryConfig
        if not migrate:
            # dict. not list.
            if fluff:
                new_node_section = 'new_' + category
            else:
                new_node_section = category
            prov_sec = ic.inventory_categories['provision'][0]
            # FIXME: account for dict.
            for n in nodes:
                if n in ic.known_instances.keys():
                    continue
                acfg[new_node_section].update(ic.provisioning_hostdefs[ic.ip_to_id_map[n]])
                acfg[prov_sec].update(ic.provisioning_hostdefs[ic.ip_to_id_map[n]])
        else:
            # dict passed my the migrate wrapper.
            acfg[category].update(nodes)

    @classmethod
    def remove_node_from_section(cls, node, category, migrate=False, use_migration_dict=True):
        """
        ClassMethod to remove a list of nodes from a list of categories within the config file. .
        """
        migration_dict = {}
        categories = [category, '{}_{}'.format('new', category)]
        if migrate:
            # Leaving only new_{category}
            del categories[categories.index(category)]
        categories += InventoryConfig.inventory_categories['provision']
        for node_key in node:
            for cat in categories:
                try:
                    cls.log.info("Removing {} from category {}".format(node_key, cat))
                    if migrate and use_migration_dict:
                        migration_dict.update({node_key: InventoryConfig.ansible_host_cfg[cat][node_key]})
                    del InventoryConfig.ansible_host_cfg[cat][node_key]
                except KeyError:
                    cls.log.debug("{} wasn't present within {} after all.".format(node_key, cat))
        if migrate:
            return migration_dict

    @classmethod
    def migrate_nodes_between_section(cls, nodes, category, additional_add=None):
        """
        Wrapper to migrate successful nodes between new_{category} and {category}
        labels within the Ansible inventory. Additionally removes node from the
        provisioning category.
        """
        if additional_add is None:
            additional_add = []
        cls.log.debug("migrate_nodes_between_section - nodes: %s category: %s additional_add: %s" % (nodes, category, additional_add))
        add_dict = cls.remove_node_from_section(nodes, category, migrate=True)
        if 'master' in category:
            _ = cls.remove_node_from_section(nodes, 'nodes', migrate=True, use_migration_dict=False)
        cls.add_nodes_to_section(add_dict, category, migrate=True)
        for addcat in additional_add:
            cls.add_nodes_to_section(add_dict, addcat, migrate=True)
        cls.log.info(
            "Nodes: {} have been permanately added to the Inventory under the {} category".format(nodes, category))
        cls.log.info("They've additionally been removed from the provision_in_progress category")

    @classmethod
    def process_playbook_json_output(cls, jout_file, category):
        """
        Processes the output from the ansible playbook run and
        determines what hosts failed / were unreachable / succeeded.

        The results are put in (Class).ansible_results, keyed by category name.
        """
        # The json_end_idx reference below is important. The playbook run is in json output,
        # however the text we're opening here is a mix of free-text and json.
        # it's formatted like this.
        #   <optional> free text
        #   Giant Glob of JSON
        #   <optional> free text.
        # The json_end_idx variable in this function defines the end of the json.
        # Without it, JSON parsing will fail.
        dt = datetime.datetime.now()
        with open(jout_file, 'r') as f:
            all_output = f.readlines()
        if len(all_output) > 1:
            json_start_idx = all_output.index('{\n')
            json_end_idx, _ = max(enumerate(all_output), key=operator.itemgetter(1))
        else:
            if len(all_output) == 1:
                cls.log.error("ansible output:")
                cls.log.error(all_output[0])
            else:
                cls.log.error("ansible produced no output")
            raise Exception('Failed to parse ansible output')

        j = json.loads(''.join(all_output[json_start_idx:json_end_idx + 1]))['stats']
        unreachable = []
        failed = []
        succeeded = []
        if 'localhost' in j.keys():
            del j['localhost']
        for h in j.keys():
            if j[h]['unreachable'] != 0:
                unreachable.append(h)
            elif j[h]['failures'] != 0:
                failed.append(h)
            else:
                succeeded.append(h)
        # ran into issues where etcd_prescale_down category key does not exist in the dict
        if category not in cls.nodes_to_add.keys():
            cls.nodes_to_add[category] = []
        # Pruning down to category only.
        cat_results = {
            'succeeded': [x for x in succeeded if x in cls.nodes_to_add[category]],
            'failed': [x for x in failed if x in cls.nodes_to_add[category]],
            'unreachable': [x for x in unreachable if x in cls.nodes_to_add[category]]
        }
        cls.ansible_results[category] = cat_results
        cls.log.info("- [{}] playbook run results: {}".format(category, cat_results))
        final_logfile = "/var/log/aws-quickstart-openshift-scaling.{}-{}-{}-{}T{}{}{}".format(
            category, dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second
        )
        os.rename(jout_file, final_logfile)
        cls.log.info("The json output logfile has been moved to %s" % final_logfile)

    @classmethod
    def summarize_playbook_results(cls):
        cls.log.debug("ansible_results: %s" % cls.ansible_results)
        for cat in cls.ansible_results.keys():
            cls.log.debug("running %s to see whether inventory must be updated" % cat)
            if not cat.startswith("pre_"):
                additional_add = []
                cjson = cls.ansible_results[cat]
                cls.log.debug("cjson: %s" % cjson)
                cls.log.info("Category: {}, Results: {} / {} / {}, ({} / {} / {})".format(
                    cat, len(cjson['succeeded']), len(cjson['failed']), len(cjson['unreachable']), 'Succeeded', 'Failed',
                    'Unreachable'))
                if cat == 'masters':
                    additional_add = ['nodes']
                cls.log.debug(
                    "running cls.migrate_nodes_between_section(%s, %s, %s)" % (cjson['succeeded'], cat, additional_add))
                cls.migrate_nodes_between_section(cjson['succeeded'], cat, additional_add=additional_add)


class LocalScalingActivity(object):
    """
    Class to objectify each scaling activity within an ASG
    """

    def __init__(self, json_doc):
        self._json = json_doc
        self.start_time = self._json['StartTime']
        self._instance_pattern = 'i-[0-9a-z]+'
        self.event_type = self._determine_scale_type()
        if self.event_type:
            self.instance = self._determine_affected_instance()
        del self._json

    def _determine_affected_instance(self):
        """
        Determines the affected instance for the scaling event.
        """
        _pattern = re.compile(self._instance_pattern)
        _instance_id = _pattern.search(self._json['Description'])
        if _instance_id:
            return _instance_id.group()
        else:
            return None

    def _determine_scale_type(self):
        """
        Determines the scaling event type (scale in, or scale out)
        """
        if self._json['StatusCode'] == 'Failed':
            return False
        _t = self._json['Description'].split()[0]
        if 'Launching' in _t:
            _type = "launch"
        elif 'Terminating' in _t:
            _type = "terminate"
        else:
            _type = None
        return _type


class LocalASG(object):
    """
    Class to objectify an ASG
    """

    def __init__(self, json_doc, version='3.9'):
        self.log = LogUtil.get_root_logger()
        self._instances = {'list': [], "scaling": []}
        self._asg = boto3.client('autoscaling', InventoryConfig.region_name)
        self.name = json_doc['AutoScalingGroupName']
        self.private_ips = list()
        self.scaling_events = list()
        self.node_hostdefs = dict()
        self.scale_in_progress_instances = {'terminate': [], 'launch': []}
        self.cooldown = json_doc['DefaultCooldown']
        self._cooldown_upperlimit = self.cooldown * 3
        self.scale_override = False
        self.logical_name = None
        self.elb_name = None
        self.stack_id = None
        self.logical_id = None
        if self._cooldown_upperlimit <= 300:
            self._cooldown_upperlimit = 300
        for tag in self._grab_tags(json_doc['Tags']):
            self.__dict__[tag['key']] = tag['value']
        self.in_openshift_cluster = self._determine_cluster_membership()
        if self.in_openshift_cluster:
            self.openshift_config_category = self._determine_openshift_category(self.logical_id)
            # Set the logical_name
            self.logical_name = InventoryConfig.logical_names[self.logical_id]
            # Sanity check to verify they're in the API.
            # - and populate the InventoryConfig.all_instances dict as a result.
            # - working around edge cases.
            ilist = [i['InstanceId'] for i in json_doc['Instances']]
            InventoryScaling.wait_for_api(instance_id_list=ilist)
            # Grab instances
            for instance in self._grab_instance_metadata(json_doc['Instances']):
                self._instances[instance.InstanceId] = instance
                self._instances['list'].append(instance.InstanceId)
                self.private_ips += instance.private_ips
            # Grab scaling events. Anything newer than (self.cooldown * 3).
            # However, only do so if we're not populating the initial inventory.
            if not InventoryConfig.initial_inventory:
                for scaling_event in self._grab_current_scaling_events():
                    self.scaling_events.append(scaling_event)
                    # If the instance is not already in the config. Done to compensate for the self._
                    # cooldown_upperlimit var.
                    if (scaling_event.event_type == 'launch') and (
                            scaling_event.instance in InventoryConfig.known_instances.keys()):
                        continue
                    if (scaling_event.event_type == 'launch') and (
                            scaling_event.instance in self.scale_in_progress_instances['terminate']):
                        continue
                    self.scale_in_progress_instances[scaling_event.event_type].append(scaling_event.instance)
                    self._instances['scaling'].append(scaling_event.instance)
                for instance in self._instances['list']:
                    # Sanity check.
                    # - If the instance is not in the known_instances list, or defined in a recent scaling event,
                    #   but is in the ASG (we dont know about it otherwise)
                    # -- Add it to the scale_in_progress list, and set scale_override to True, so a scale-up occurs.
                    #    (See: scaler.scale_
                    if (instance not in InventoryConfig.known_instances.keys()) and (
                            instance not in self._instances['scaling']):
                        self.scale_in_progress_instances['launch'].append(instance)
                        self.scale_override = True
            # Grab Inventory host definitions
            for combined_hostdef in self.generate_asg_node_hostdefs(version):
                instance_id, hostdef = combined_hostdef
                InventoryConfig.id_to_ip_map[instance_id] = hostdef['ip_or_dns']
                del hostdef['ip_or_dns']
                InventoryConfig.provisioning_hostdefs[instance_id] = hostdef
                self.node_hostdefs.update(hostdef)

    @staticmethod
    def _grab_tags(tag_json):
        """
        Descriptor to grabs the tags for an ASG
        """
        i = 0
        while i < len(tag_json):
            if 'cloudformation' in tag_json[i]['Key']:
                _k = tag_json[i]['Key'].split(':')[2]
                yield {'key': _k.lower().replace('-', '_'), 'value': tag_json[i]['Value']}
            i += 1

    def _determine_cluster_membership(self):
        """
        Determines if the ASG is within the OpenShift Cluster
        """
        if self.stack_id == InventoryConfig.stack_id:
            self.log.debug("{} matches {} for ASG: {}".format(self.stack_id, InventoryConfig.stack_id, self.name))
            self.log.info("Awesome! This ASG is in the openshift cluster:" + self.name)
            return True
        self.log.debug("{} != {} for ASG: {}".format(self.stack_id, InventoryConfig.stack_id, self.name))
        self.log.info("This ASG is not in the openshift cluster")
        return False

    def _grab_current_scaling_events(self):
        """
        Descriptor to query the EC2 API to fetch the current scaling events for the ASG.
        """
        _now = datetime.datetime.now().replace(tzinfo=dateutil.tz.tzlocal())
        scaling_activities = self._asg.describe_scaling_activities(AutoScalingGroupName=self.name)['Activities']
        i = 0
        while i < len(scaling_activities):
            _se = LocalScalingActivity(scaling_activities[i])
            i += 1
            # If the scaling activity was not successful, move along.
            if not _se.event_type:
                continue
            _diff = _now - _se.start_time
            if (_se.event_type == 'terminate') and (_se.instance in InventoryConfig.known_instances.keys()):
                yield _se
            elif _diff.days == 0 and (_diff.seconds <= self._cooldown_upperlimit):
                yield _se

    @staticmethod
    def _grab_instance_metadata(json_doc):
        """
        Generator to grab the metadata of the ansible controller (local) instance.
        """
        i = 0
        while i < len(json_doc):
            yield LocalASInstance(json_doc[i]['InstanceId'])
            i += 1

    @staticmethod
    def _determine_openshift_category(logical_id):
        """
        Determine the openshift category (etcd/nodes/master)
        """
        try:
            openshift_category = InventoryConfig.logical_names[logical_id]
        except KeyError:
            return None
        return openshift_category

    def generate_asg_node_hostdefs(self, version='3.9'):
        # - ADD IN FILE TO READ FROM DISK FOR DYNAMIC NODE LABELS.
        """
        Generates the host definition for populating the Ansible Inventory.
        """
        i = 0
        while i < len(self._instances['list']):
            instance_id = self._instances['list'][i]
            node = self._instances[instance_id]
            # https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_InstanceState.html
            if node.State['Code'] not in [0, 16]:
                i += 1
                continue
            _ihd = {'instance_id': instance_id}
            if version == '3.9':
                _ihd.update({
                    'openshift_node_labels': {
                        'application_node': 'yes',
                        'registry_node': 'yes',
                        'router_node': 'yes',
                        'region': 'infra',
                        'zone': 'default'
                    }
                })

            if version != '3.9':
                if 'glusterfs' in self.openshift_config_category:
                    _ihd.update({'openshift_node_group_name': 'node-config-glusterfs'})
                else:
                    _ihd.update({'openshift_node_group_name': 'node-config-compute-infra'})

            if 'master' in self.openshift_config_category:
                print("making schedulable")
                _ihd.update({'openshift_schedulable': 'true'})
                if version == '3.9':
                    _ihd.update({
                        'openshift_node_labels': {
                            'region': 'primary',
                            'zone': 'default'
                        }
                    })
                else:
                    print('setting node group')
                    _ihd['openshift_node_group_name'] = 'node-config-master'
                if self.elb_name:
                    # openshift_public_hostname is only needed if we're dealing with masters, and an ELB is present.
                    _ihd['openshift_public_hostname'] = self.elb_name
            elif 'glusterfs' in self.openshift_config_category:
                _ihd.update({
                     'glusterfs_devices': ["/dev/xvdc"]
                })
            elif 'node' not in self.openshift_config_category:
                # Nodes don't need openshift_public_hostname (#3), or openshift_schedulable (#5)
                # etcd only needs hostname and node labes. doing the 'if not' above addresses both
                # of these conditions at once, as the remainder are default values prev. defined.
                if version == '3.9':
                    del _ihd['openshift_node_labels']
                else:
                    del _ihd['openshift_node_group_name']

            hostdef = {node.PrivateDnsName: _ihd, 'ip_or_dns': node.PrivateDnsName}
            i += 1
            yield (instance_id, hostdef)


class LocalASInstance(object):
    """
    Class around each instance within an ASG
    """

    def __init__(self, instance_id):
        self.private_ips = []
        self.InstanceId = None
        self.State = None
        self.PrivateDnsName = None
        try:
            instance_object = InventoryConfig.all_instances[instance_id]
            for ip in self._extract_private_ips(instance_object['NetworkInterfaces']):
                self.private_ips.append(ip)
            self.__dict__.update(**instance_object)
        except KeyError:
            pass

    @staticmethod
    def _extract_private_ips(network_json):
        """
        Generator that extracts the private IPs from the instance.
        """
        i = 0
        while i < len(network_json):
            yield network_json[i]['PrivateDnsName']
            i += 1


class ClusterGroups(object):
    """
    Class around the ASGs within the Cluster
    """
    groups = []

    @classmethod
    def setup(cls, version='3.9'):
        for group in cls._determine_cluster_groups(version):
            cls.groups.append(group)

    @classmethod
    def _determine_cluster_groups(cls, version):
        """
        Generator that determines what ASGs are within the cluster.
        """
        asg = boto3.client('autoscaling', InventoryConfig.region_name)
        all_groups = asg.describe_auto_scaling_groups()['AutoScalingGroups']
        i = 0
        while i < len(all_groups):
            _g = LocalASG(all_groups[i], version)
            i += 1
            if _g.in_openshift_cluster:
                yield _g

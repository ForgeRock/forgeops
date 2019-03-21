#!/usr/bin/env python
import argparse
import subprocess
import tempfile
import shlex
import time
import sys
import os
from .utils import InventoryConfig, ClusterGroups, InventoryScaling
from .logger import LogUtil
import yaml


LogUtil.set_log_handler('/var/log/openshift-quickstart-scaling.log')
log = LogUtil.get_root_logger()


def generate_inital_inventory_nodes(write_hosts_to_temp=False, version='3.9'):
    """
    Generates the initial ansible inventory. Instances only.
    """

    # TODO: Add debugging statements
    def _varsplit(filename):
        if not os.path.exists(filename):
            return {}
        if os.path.getsize(filename) == 1:
            return {}
        _vs = {}
        with open(filename, 'r') as fo:
            varlines = fo.readlines()
        for l in varlines:
            try:
                l_stripped = l.strip('\n')
                if l_stripped == '':
                    continue
                k, v = l_stripped.split('=', 1)
                if ((v[0] == "'") and (v[-0] == "'")) or ((v[0] == '"') and (v[-0] == '"')):
                    v = v[1:-1]
                _vs[k] = v
            except ValueError:
                log.error("I ran into trouble trying to unpack this value: \"{}\".".format(l))
                log.error("I cannot proceed further. Exiting!")
                sys.exit(1)
        return _vs

    # Inventory YAML file format:
    # - http://docs.ansible.com/ansible/2.5/plugins/inventory/yaml.html
    # OSEv3:
    #   children:
    #       masters:
    #           hosts:
    #               (...)
    #       new_masters:
    #           hosts:
    #               (...)
    #       etcd:
    #           hosts:
    #               (...)
    #       nodes:
    #           hosts:
    #               (...)
    #   vars:
    #       foo: bar
    #       (...)

    # Need to have the masters placed in the nodes section as well
    _initial_ansible_skel = {
        'OSEv3': {
            'children': {},
            'vars': {}
        }
    }

    # Vars are in three parts:
    # - Pre-defined vars.
    # - Userdata vars.
    # - User-defined vars.
    # Pre-defined: Applies in all circumstances
    # Userdata: Applies as a result of Template conditions.
    # User-defined: Passed as input to the template.

    # TODO: migrate legacy config to yaml
    # - Pre-defined vars.
    _vars = {}
    for f in ['/tmp/openshift_inventory_predefined_vars', '/tmp/openshift_inventory_userdata_vars', '/tmp/openshift_inventory_userdef_vars']:
        _is_yaml = True
        try:
            _pre_defined_vars = yaml.safe_load(open(f))
        except Exception:
            _is_yaml=False
            _pre_defined_vars = None
        if type(_pre_defined_vars) != dict:
            _is_yaml = False
        if not _is_yaml:
            _pre_defined_vars = _varsplit(f)
        _vars.update(_pre_defined_vars)

    _children = {}

    # Children
    # - group.node_hostdefs are now a dict. previously a list.
    for group in ClusterGroups.groups:
        group_hostdefs = {
            group.openshift_config_category: {
                'hosts': group.node_hostdefs
            }
        }
        _children.update(group_hostdefs)

    # Masters/glusterfs as nodes for the purposes of software installation.
    _children['nodes']['hosts'].update(_children['masters']['hosts'])
    if 'glusterfs' in _children.keys():
        _children['nodes']['hosts'].update(_children['glusterfs']['hosts'])

    # Pushing the children and vars into the skeleton
    _initial_ansible_skel['OSEv3']['children'].update(_children)
    _initial_ansible_skel['OSEv3']['vars'].update(_vars)

    # Pushing the skeleton to the ClassVar.
    InventoryConfig.ansible_full_cfg.update(_initial_ansible_skel)

    # Making sure the new_{category} keys are present, too.
    # - If no save was done as a part of the verification function, write to disk.
    InventoryConfig.verify_required_sections_exist(generate=True)
    InventoryConfig.write_ansible_inventory_file(init=True)

    if write_hosts_to_temp:
        for cat in _children.keys():
            for host in _children[cat]['hosts'].keys():
                with open('/tmp/openshift_initial_{}'.format(cat), 'w') as f:
                    f.write(host + '\n')

    return 0


def run_ansible_playbook(category=None, playbook=None, extra_args=None, prepared_commands=None):
    """
    Wrapper for running an ansible playbook.
    :param category: Category to label this playbook invocation as (pre_etcd_teardown, etcd, nodes, so on) [OPTIONAL]
    :param playbook: path to playbook to run
    :param extra_args: extra_args to run with the playbook. [OPTIONAL]
    :param prepared_commands: list of prepared commands. Bypasses command construction.
    """
    proc_cat = {}
    file_cat = {}
    completed_numproc = 0
    completed_procs = []
    log.debug("category: %s, playbook: %s, extra_args: %s, prepared_commands %s" % (category, playbook, extra_args, prepared_commands))
    if not prepared_commands:
        if not category:
            raise Exception("category is required if prepared_commands is not specified")
        ansible_cmd = "{} {}".format("ansible-playbook", playbook)
        if extra_args:
            ansible_cmd = "{} {}".format(ansible_cmd, '{}"{}"'.format('--extra-vars=', str(extra_args)))
        prepared_commands = {category: ansible_cmd}
    fnull = open(os.devnull, 'w')
    log.debug("prepared_commands: " % prepared_commands)
    for category in prepared_commands.keys():
        command = prepared_commands[category]
        log.debug("executing command for category %s is: %s" % (category, command))
        stdout_tempfile = tempfile.mkstemp()[1]
        with open(stdout_tempfile, 'w') as fileout:
            process = subprocess.Popen(shlex.split(command), stdout=fileout, stderr=fnull)
            proc_cat[category] = process
            file_cat[category] = stdout_tempfile
    numcats = len(proc_cat.keys())
    log.info("We have {} ansible playbooks running!".format(numcats))
    while True:
        if numcats == completed_numproc:
            break
        for cat in proc_cat.keys():
            p = proc_cat[cat]
            if p in completed_procs:
                continue
            if p.poll() is not None:
                log.info("- A process completed. We're parsing it...")
                InventoryScaling.process_playbook_json_output(jout_file=file_cat[cat], category=cat)
                completed_procs.append(p)
                completed_numproc += 1
                log.info("- complete! We have {} to go...".format((numcats - completed_numproc)))


def scale_inventory_groups(ocp_version='3.7'):
    """
    Processes the scaling activities.
    - Fires off the ansible playbook if needed.
    - Prunes the ansible inventory to remove instances that have scaled down / terminated.
    :param ocp_version: Version of the OpenShift Container Platform that's in use. Defaults to 3.7.
    """

    InventoryConfig.ip_to_id_map = {v: k for (k, v) in InventoryConfig.id_to_ip_map.iteritems()}
    # First, we just make sure that there's *something* to add/remove.
    api_state = False
    attempts = 0
    total_scaled_nodes = []
    log.info("Verifying that the API reflects the scaling events properly")
    while api_state is False:
        for group in ClusterGroups.groups:
            total_scaled_nodes += group.scale_in_progress_instances['terminate']
            total_scaled_nodes += group.scale_in_progress_instances['launch']
        if attempts > 12:
            log.info("No scaling events were populated. 2 minute timer expired. Moving on...")
            break
        if len(total_scaled_nodes) == 0:
            time.sleep(10)
            ClusterGroups.setup(ocp_version)
            attempts += 1
        else:
            log.info("Great! The API contains scaling events that we need to process!")
            api_state = True

    _is = InventoryScaling
    scaleup_needed = False
    scaledown_needed = False
    for group in ClusterGroups.groups:
        if (not group.scale_override) and (not group.scaling_events):
            continue
        # Here we add the instance IDs to the termination and launchlist.
        _is.nodes_to_remove[group.logical_name] += group.scale_in_progress_instances['terminate']
        _is.nodes_to_add[group.logical_name] += group.scale_in_progress_instances['launch']

        # duplicate this to the combined list.
        _is.nodes_to_add['combined'] += _is.nodes_to_add[group.logical_name]
        _is.nodes_to_remove['combined'] += _is.nodes_to_remove[group.logical_name]

    if _is.nodes_to_remove['combined']:
        scaledown_needed = True

    if _is.nodes_to_add['combined']:
        scaleup_needed = True
        # We wait for the API to populate with the new instance IDs.
        _is.wait_for_api()

    # Now we convert the IDs in each list to IP Addresses.
    for e in _is.nodes_to_add.keys():
        _templist = []
        for instance_id in _is.nodes_to_add[e]:
            _templist.append(InventoryConfig.id_to_ip_map[instance_id])
        _is.nodes_to_add[e] = _templist

    for e in _is.nodes_to_remove.keys():
        _templist = []
        for instance_id in _is.nodes_to_remove[e]:
            try:
                _templist.append(InventoryConfig.known_instances[instance_id])
            except KeyError:
                continue
        _is.nodes_to_remove[e] = _templist

    scaledown_extra_args = {
        'etcdremove':   _is.nodes_to_remove['etcd'],
        'noderemove':   _is.nodes_to_remove['nodes'],
        'masterremove': _is.nodes_to_remove['masters']
    }
    scaleup_extra_args = {
        'etcdadd':   _is.nodes_to_add['etcd'],
        'nodeadd':   _is.nodes_to_add['nodes'],
        'masteradd': _is.nodes_to_add['masters']
    }
    log.debug("scaleup_needed: %s" % scaleup_needed)
    log.debug("scaledown_needed: %s" % scaledown_needed)
    log.debug("scaleup_extra_args: %s" % scaleup_extra_args)
    log.debug("scaledown_extra_args: %s" % scaledown_extra_args)
    if scaledown_needed:
        # Housekeeping.
        # TODO: YAML Config
        if _is.nodes_to_remove['masters']:
            _is.nodes_to_remove['nodes'] += _is.nodes_to_remove['masters']
        log.info("Performing pre-scaledown tasks.")
        run_ansible_playbook(category='pre_scaledown_tasks',
                             playbook=InventoryConfig.pre_scaledown_playbook,
                             extra_args=scaledown_extra_args)
    if scaleup_needed:
        # Housekeeping.
        # TODO: YAML Config
        if _is.nodes_to_add['masters']:
            _is.nodes_to_add['nodes'] += _is.nodes_to_add['masters']
        log.info("We've detected that we need to run ansible playbooks to scale up the cluster!")
        log.info("Performing pre-scaleup tasks.")
        run_ansible_playbook(category='pre_scaleup_tasks',
                             playbook=InventoryConfig.pre_scaleup_playbook,
                             extra_args=scaleup_extra_args)
    _is.process_pipeline()
    InventoryConfig.write_ansible_inventory_file()

    # See note above about new_masters/new_nodes; This weeds those out.
    # Housekeeping.
    # TODO: YAML Config
    _n = _is.nodes_to_add['masters']
    _m = _is.nodes_to_add['nodes']
    for host in _m:
        if host in _n:
            del _is.nodes_to_add['nodes'][_n.index(host)]

    ansible_commands = {}
    for category in InventoryConfig.inventory_node_skel.keys():
        if category is 'provision':
            continue
        if category in ['etcd', 'glusterfs']:
            _is_cat_name = category
        else:
            _is_cat_name = "{}{}".format(category, 's')
        # categories are plural in the nodes_to_add dict, singular in everything else.
        if len(_is.nodes_to_add[_is_cat_name]) == 0:
            continue
        provisioning_category = InventoryConfig.inventory_categories['provision'][0]
        svars = {"target": provisioning_category, "scaling_category": category}
        if ocp_version != '3.7':
            svars['scale_prefix'] = '/usr/share/ansible/openshift-ansible/playbooks'
        _extra_vars = '{}"{}"'.format('--extra-vars=', str(svars))
        _ansible_cmd = "{} {} {}".format(
            "ansible-playbook",
            InventoryConfig.ansible_playbook_wrapper,
            _extra_vars
        )
        log.info("We will run the following ansible command:")
        log.info(_ansible_cmd)
        ansible_commands[_is_cat_name] = _ansible_cmd

    run_ansible_playbook(prepared_commands=ansible_commands)
    InventoryConfig.write_ansible_inventory_file()
    _is.summarize_playbook_results()
    InventoryConfig.write_ansible_inventory_file()

    if scaleup_needed:
        log.info("Performing post-scaleup tasks.")
        run_ansible_playbook(category='post_scaleup_tasks',
                             playbook=InventoryConfig.post_scaleup_playbook)

    if scaledown_needed:
        log.info("Performing post-scaledown tasks.")
        run_ansible_playbook(category='post_scaledown_tasks',
                             playbook=InventoryConfig.post_scaledown_playbook)


def check_for_pid_file():
    pidfile = "/run/aws-qs-ose-scaler.pid"
    if not os.path.exists(pidfile):
        pid = str(os.getpid())
        with open(pidfile, 'w') as f:
            f.write(pid)
    else:
        log.info("Another invocation of this script is running. Exiting.")
        sys.exit(0)


def main():
    log.info("--------- Begin Script Invocation ---------")
    parser = argparse.ArgumentParser()
    parser.add_argument('--debug', action='store_true')
    parser.add_argument('--generate-initial-inventory',
                        help='Generate the initial nodelist and populate the Ansible Inventory File',
                        action='store_true')
    parser.add_argument('--scale-in-progress',
                        help='Indicate that a Scaling Action is in progress in at least one cluster Auto Scaling Group',
                        action='store_true')
    parser.add_argument('--write-hosts-to-tempfiles', action='store_true', dest='write_to_temp',
                        help='Writes a list of initial hostnames to /tmp/openshift_initial_$CATEGORY')
    parser.add_argument('--ocp-version', help='Openshift version, eg. "3.10", default is 3.9', default='3.9')
    args = parser.parse_args()

    if args.debug:
        log.info("Enabling loglevel DEBUG...")
        log.handlers[0].setLevel(10)
        log.debug("enabled!")

    if args.write_to_temp:
        write_to_temp = True
    else:
        write_to_temp = False

    if args.generate_initial_inventory:
        InventoryConfig.initial_inventory = True
        InventoryConfig.setup()
        ClusterGroups.setup(args.ocp_version)
        generate_inital_inventory_nodes(write_hosts_to_temp=write_to_temp, version=args.ocp_version)
        sys.exit(0)

    log.debug("Passed arguments: {} ".format(args.__dict__))
    InventoryConfig.setup()
    # This function call should be moot under normal circumstances.
    # - However if someone modifies the ansible inventory, we need to
    # - account for that possibility.
    InventoryConfig.verify_required_sections_exist()
    InventoryConfig.populate_from_ansible_inventory()
    ClusterGroups.setup(args.ocp_version)

    if args.scale_in_progress:
        InventoryConfig.scale = True
        scale_inventory_groups(ocp_version=args.ocp_version)
    log.info("////////// End Script Invocation //////////")

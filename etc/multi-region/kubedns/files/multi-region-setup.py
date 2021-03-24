#!/usr/bin/env python

# Multi-region DS: this script sets up a global DNS across multiple GKE clusters so that servers in all
# clusters can be reached using their FQDN.

from __future__ import print_function

import distutils.spawn
import json
import os
import copy


from subprocess import check_call, check_output
from sys import exit, argv
from time import sleep

DRY_RUN = False
namespace = "default"
services = []

# Map of (region, context), which is initially empty and will be filled from script arguments
contexts = {
    # example values that will be filled in
    #'us': 'gke_engineering-devops_us-west2-a_ds-wan-replication-us',
    #'europe': 'gke_engineering-devops_europe-west2-b_ds-wan-replication'
}

# Utility method to perform a system call or do nothing when in dry-run mode
def call(args):
  if DRY_RUN:
    print(" ".join(args))
  else:
    check_call(args)

# Utility method to perform a system call and return the result or do nothing when in dry-run mode (returns a dummy value)
def output(args):
  if DRY_RUN:
    print(" ".join(args))
    return b'1.2.3.4'
  else:
    return check_output(args)

# Read script arguments: there are 3 expected arguments
# 1) namespace: the unique namespace used across regions
# 2) service_list: comma-separated list of services
# 3) cluster_map: comma-separated list of (region, gke context) pairs. A pair is using the format by "key:value"
# Example: multi-region ds-idrepo,ds-cts us:gke-us-context,europe:gke-eu-context
def read_args():
  n = len(argv)
  if n < 4 or n > 5:
      print("""\
this script sets up a global DNS across multiple GKE clusters for multi-region DS deployment

Usage:  multi-region-setup.py namespace service1,service2,... region1:gke_context_1,region2:gke_context_2,... [dry-run]

If last argument 'dry-run' is provided (actually any value is ok), the script only outputs what would be done.
""")
      exit(1)
  global namespace
  global services
  global DRY_RUN
  namespace = argv[1]
  services = argv[2].split(",")
  regions_and_contexts = argv[3].split(",")
  for region_and_context in regions_and_contexts:
    region, context = region_and_context.split(":")
    contexts[region] = context
  if n == 5:
      print("--- Running the script in dry-run mode ---\n")
      DRY_RUN = True

# Set the path to the directory where the generated yaml files will be stored
generated_files_dir = '../generated'

try:
    os.mkdir(generated_files_dir)
except OSError:
    pass

# Create a load balancer for the DNS pods in each k8s cluster
def create_dns_lb():
    for region, context in contexts.items():
    	call(['kubectl', 'apply', '-f', 'dns-lb.yaml', '--context', context])

# Set up each load balancer to forward DNS requests for zone-scoped namespaces to the
# relevant cluster's DNS server, using the external IP of the internal load balancers
def retrieve_dns_lb_ip_per_region():
    dns_ips = dict()
    for region, context in contexts.items():
        external_ip = ''
        while True:
            external_ip = output([
                    'kubectl', 'get', 'svc', 'kube-dns-lb', '--namespace', 'kube-system', '--context',
                    context, '--template', '{{range .status.loadBalancer.ingress}}{{.ip}}{{end}}'])
            if external_ip:
                break
            print('Waiting for DNS load balancer IP in %s...' % (region))
            sleep(10)
        ip_as_string = external_ip.decode("utf-8")
        print('DNS endpoint for region %s: %s' % (region, ip_as_string))
        dns_ips[region] = ip_as_string
    return dns_ips

def generate_config_map(previous_config, new_config):
    return """\
apiVersion: v1
kind: ConfigMap
metadata:
  name: kube-dns
  namespace: kube-system
data:
  stubDomains: |
    %s
""" % (merge_json_configs(previous_config, new_config))

def merge_json_configs(config1, config2):
   if config1.startswith(b'<no value>'):
      return json.dumps(config2)
   json1 = json.loads(config1)
   json2 = config2
   config = copy.deepcopy(json1)
   config.update(json2)
   return json.dumps(config)

# Update each cluster's DNS configuration with an appropriate configmap.
# Previous values in configmap are kept if they not conflict with the new values.
#
# Note that we have to ensure that the local cluster is not added to its own configmap
# since those requests do not go through the load balancer. Finally, we have to delete the
# existing DNS pods in order for the new configuration to take effect.
def update_dns_config(dns_ips):
    for region, context in contexts.items():
        remote_dns_ips = dict()
        previous_config = output(['kubectl', 'get', 'configmap', 'kube-dns', '--context', context, '-n', 'kube-system',
                                  '--template', '{{.data.stubDomains}}'])
        for reg, ip in dns_ips.items():
            if reg == region:
                continue
            for service in services:
              remote_dns_ips[service + "-" + reg + '.' + namespace + '.svc.cluster.local'] = [ip]
        config_filename = '%s/dns-configmap-%s.yaml' % (generated_files_dir, region)
        with open(config_filename, 'w') as f:
            # config map is built from previous config and new config, in order to update only
            config = generate_config_map(previous_config, remote_dns_ips)
            f.write(config)
        call(['kubectl', 'apply', '-f', config_filename, '--namespace', 'kube-system',
              '--context', context])
        call(['kubectl', 'delete', 'pods', '-l', 'k8s-app=kube-dns', '--namespace', 'kube-system',
              '--context', context])




## Main
read_args()
create_dns_lb()
dns_lb_ips = retrieve_dns_lb_ip_per_region()
update_dns_config(dns_lb_ips)


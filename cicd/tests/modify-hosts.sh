#!/usr/bin/env bash
#
# Helper script to set /etc/hosts to values provided by ingress
# set NAMESPACE variable to use different NS then RunSmokeTest/
#
# Used in cloudbuilder to access deployed product endpoints
#
# You can use this script as a standalone one for forgeops deployments,
# but don't forget to run it with sudo to have access to /etc/hosts.


NAMESPACE=${NAMESPACE:-smoke}

echo "Setting /etc/hosts for ingress in namespace ${NAMESPACE}"
INGRESS_IP=$(kubectl -n=${NAMESPACE} get ingress -o jsonpath='{.items[0].status.loadBalancer.ingress[*].ip}')
INGRESS_FQDN=$(kubectl -n=${NAMESPACE} get ingress -o jsonpath='{.items[*].spec.rules[*].host}' )

for fqdn in ${INGRESS_FQDN}
do
  echo ${INGRESS_IP} ${fqdn} >> /etc/hosts
done

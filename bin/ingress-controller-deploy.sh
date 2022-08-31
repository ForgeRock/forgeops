#!/usr/bin/env bash
# Script to deploy an ingress chart using Helm3 to either EKS/GKE or AKS.
#set -oe pipefail

# Version is currently not used. We default to installing the latest stable version in the helm repo.
#VERSION="0.34.1"

# Grab our starting dir
start_dir=$(pwd)
# Figure out the dir we live in
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# Bring in our standard functions
source $SCRIPT_DIR/stdlib.sh
cd $start_dir

usage() {
    exit_code=$1
    err=$2
    prog=$(basename $0)
    cat <<EOM
Usage: $prog [-g|--gke] [-e|--eks] [-a|--aks] [-d|delete] [-h|--help] [-i|--ingress {haproxy,nginx}] [<ip_address>]

Install the haproxy or nginx ingress chart.

NOTES:
  * Supplying the IP address only works when installing to GKE.
  * The IP address must be the last option.

  OPTIONS:
    -h|--help                    : display usage and exit
    --debug                      : enable debugging output
    --dryrun                     : do a dry run
    -v|--verbose                 : be verbose
    -a|--aks                     : deploy to AKS
    -e|--eks                     : deploy to EKS
    -g|--gke                     : deploy to GKE. Optionally provide IP address (default: dynamically generate IP address)
    -i|--ingress {haproxy,nginx} : choose ingress chart (default: nginx)

Requirements:
  * helm installed
  * kubectl installed

Examples:
  GKE without an IP using default chart:
  $prog -g

  GKE with an IP using default chart:
  $prog -g 1.2.3.4

  GKE with an IP using haproxy chart:
  $prog -g -i haproxy 1.2.3.4

  AKS using haproxy chart:
  $prog -a -i haproxy

EOM

  if [ ! -z "$err" ] ; then
    echo "ERROR: $err"
    echo
  fi

  exit $exit_code
}

# Delete Helm chart
delete() {
    echo "Deleting $CHART Helm chart."
    runOrPrint "helm uninstall $CHART --namespace $NAMESPACE || true"
    exit 1
}

# Defaults
DEBUG=false
DRYRUN=false
VERBOSE=false
DELETE=false
INGRESS=nginx
IP=
IP_OPTS=
AKS=false
EKS=false
GKE=false

while true; do
  case "$1" in
    -h|--help) usage 0 ;;
    --debug) DEBUG=true; shift ;;
    --dryrun) DRYRUN=true; shift ;;
    -v|--verbose) VERBOSE=true; shift ;;
    -d|--delete) DELETE=true; shift ;;
    -a|--aks) AKS=true; shift ;;
    -e|--eks) EKS=true; shift ;;
    -g|--gke) GKE=true; shift ;;
    -i|--ingress) INGRESS=$2; shift 2 ;;
    *) [[ -n "$1" ]] && IP=$1
       break
       ;;
  esac
done

message "DEBUG=$DEBUG" "debug"
message "DRYRUN=$DRYRUN" "debug"
message "VERBOSE=$VERBOSE" "debug"
message "DELETE=$DELETE" "debug"
message "INGRESS=$INGRESS" "debug"
message "IP=$IP" "debug"

if [[ "$GKE" = true && ("$AKS" = true || "$EKS" = true) ]] || \
   [[ "$AKS" = true && ("$GKE" = true || "$EKS" = true) ]] || \
   [[ "$EKS" = true && ("$GKE" = true || "$AKS" = true) ]] ; then
     usage 1 "You must pick one cloud (-a, -e, or -g)"
fi

if [ "$AKS" = true ] ; then
  echo "Deploying Ingress chart to AKS..."
  PROVIDER="aks"
elif [ "$EKS" = true ] ; then
  echo "Deploying Ingress chart to EKS..."
  PROVIDER="eks"
elif [ "$GKE" = true ] ; then
  if [ -n "$IP" ] ; then
    message "We were given an IP address" "debug"
    [[ ! "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && usage 1 "Can't detect a valid IP address"
    echo "IP: $IP"
    IP_OPTS="--set chart.service.loadBalancerIP=${IP}"
  fi
  echo "Deploying Ingress chart to GKE..."
  PROVIDER="gke"
fi

message "PROVIDER=$PROVIDER" "debug"

case $INGRESS in
  haproxy)
    CHART=haproxy-ingress
    NAMESPACE=haproxy
    REPO=https://haproxy-ingress.github.io/charts
    REPO_NAME=haproxy-ingress
    ;;
  nginx)
    CHART=ingress-nginx
    NAMESPACE=nginx
    REPO=https://kubernetes.github.io/ingress-nginx
    REPO_NAME=ingress-nginx
    ;;
  *)
    usage 1 "You must pick either haproxy or nginx as an ingress"
    ;;
esac

if [ "$DELETE" = true ] ; then
  delete
fi

# Create namespace
ns=$(kubectl get namespace | grep $NAMESPACE | awk '{ print $1 }' || true)

# Identify cluster size
clustsize=$(kubectl get nodes --label-columns forgerock.io/cluster --no-headers  | head -n 1 | awk '{print $6}')

if [ -z "${ns}" ]; then
    runOrPrint "kubectl create namespace $NAMESPACE"
else
    echo "*** $NAMESPACE namespace already exists ***"
fi

if [ -n "$clustsize" ]; then
    echo "Detected cluster of type: $clustsize"
fi

if [[ -n "$clustsize" && ($clustsize == "cdm-medium" || $clustsize == "cdm-large") ]]; then
    echo "Setting ingress pod count to 3"
    INGRESS_POD_COUNT=3
elif [[ -n "$clustsize" && ($clustsize == "cdm-small") ]]; then
    echo "Setting ingress pod count to 2"
    INGRESS_POD_COUNT=2
else
    echo "Setting ingress pod count to 1"
    INGRESS_POD_COUNT=1
fi

# Set script location
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ADDONS_BASE="${ADDONS_BASE:-${DIR}/../cluster/addons}"
ADDONS_DIR="${ADDONS_BASE}/${NAMESPACE}-ingress-controller"

# Add Helm repo
runOrPrint "helm repo add $REPO_NAME $REPO --force-update"

# Deploy ingress Helm chart
runOrPrint "helm upgrade -i $CHART --namespace $NAMESPACE $REPO_NAME/$CHART \
    $IP_OPTS -f ${ADDONS_DIR}/${PROVIDER}.yaml --set chart.replicaCount=${INGRESS_POD_COUNT}"

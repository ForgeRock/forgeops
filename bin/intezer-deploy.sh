#!/usr/bin/env bash

set -oe pipefail

NAMESPACE=intezer
VERSION="7.1.6"
KEY=

# Print usage message to screen
usage() {
    cat <<EOF
Usage:
    $0 [options]

Options:
    --key <license_key>		license key for installation (required)
    --uninstall         	uninstall helm chart

Example:
    $0 --key <license_key>
EOF
    exit 2
}

deploy() {
    [ -z "$KEY" ] && echo "A license key is required" && usage
    kubectl create namespace $NAMESPACE || true
    helm upgrade intezer \
        oci://us-docker.pkg.dev/forgeops-public/charts/intezer \
	--version $VERSION --namespace $NAMESPACE --install \
	--set sensorConfig.license_key="$KEY"
}

uninstall() {
    helm --namespace $NAMESPACE uninstall intezer
    kubectl delete namespace $NAMESPACE
    exit 0
}

while [ $# -gt 0 ]; do
    case $1 in
        --help)
            usage
            ;;
        --key)
            KEY=$2
            shift; shift
            ;;
        --uninstall)
            uninstall
            ;;
        *)
            usage
            ;;
    esac
done

# Deploy intezer
deploy


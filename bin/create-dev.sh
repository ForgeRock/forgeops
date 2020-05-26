#!/usr/bin/env bash
## Creates a development skaffold profile using your chosen FQDN and namespace
## This is EXPERIMENTAL (unsupported) and will be replaced by a more robust mechanism in the future.
## It is used internally in ForgeRock to help developers share a cluster.
## Usage:
## create-dev.sh -f FQDN -n namespace -d dockerRegistry
##   -f fqdn the fully qualified domain name for the platform. Defaults to default.iam.example.com
##    -n namespace  Kubernetes namespace. Defaults to default
##    -d The docker registry to push your images to. Defaults to gcr.io/engineering-devops
##
## Example:
##     create-dev.sh -n default -f acme.iam.foo.com -f gcr.io/my-registry

set -o pipefail

[[ "${FR_DEBUG}" == true ]] && set -x

FQDN="${FQDN:-default.iam.example.com}"
DOCKER_REPO="${DOCKER_REPO:-gcr.io/engineering-devops}"

usage() {
      awk -F'## ' '/^##/ { print $2 }' "$0"
 }

load_ns () {
    ns=$(kubectl config view --minify --output 'jsonpath={..namespace}' | tr -d '\n')
    if [[ "${ns}" == "" ]];
    then
        # return nothing validation will throw error
        return 1
    fi
    echo "${ns}"
}

NAMESPACE=$(load_ns)


# Creates a ./dev folder that contains kustomize base patched to use the desired FQDN
create_dev_config() {
  CDIR=./dev
  echo "Generating Kustomize template in $CDIR directory for $FQDN"
  mkdir -p "$CDIR"
  cat <<EOF >"$CDIR/kustomization.yaml"
# Generated Kustomization file. Edit this for your requirements.
# This deploys to the ingress $FQDN in the $NAMESPACE
namespace: $NAMESPACE
resources:
- ../kustomize/overlay/7.0/all

patchesStrategicMerge:
- |-
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: platform-config
  data:
    # EDIT The variables below for your deployment
    FQDN: $FQDN
    # This uses a cert-manager Let's Encrypt (LUE) issuer. Comment this out if you are not using cert-manager and LE
    CERT_ISSUER: letsencrypt-prod
EOF

  echo "Creating $CDIR/run.sh script"
  cat >"$CDIR/run.sh" <<EOF
#!/usr/bin/env bash
# Generated script - edit for your requirements
# Run this from the root of forgeops using ./dev/run.sh

# This copies the default (CDK) configuration to the docker/folders.
./bin/config.sh init

# Specify the skaffold profile to use with -p
# dev - use the docker builder profile
# kdev - the Kaniko in-cluster builder.
skaffold --default-repo=$DOCKER_REPO -p dev run --tail

# To delete the deployment:
# skaffold -p dev delete
# ./bin/clean.sh
EOF
  chmod +x $CDIR/run.sh


  echo "Configuration created in ./dev. REVIEW AND EDIT THESE FILES"

}

# handle opts
while getopts n:f:g:d:h option; do
  case "${option}" in

  n) NAMESPACE=${OPTARG} ;;
  f) FQDN=${OPTARG} ;;
  d) DOCKER_REPO=${OPTARG};;
  h)
    usage
    exit 0
    ;;
  *)
    usage
    exit 1
    ;;
  esac
done
shift $((OPTIND - 1))

create_dev_config


#!/usr/bin/env bash
# This is EXPERIMENTAL (unsupported) and will be replaced by a more robust mechanism in the future.
# It is used internally in ForgeRock to help developers share a cluster.

set -o pipefail

[[ "${FR_DEBUG}" == true ]] && set -x

NAMESPACE="${NAMESPACE}"
FQDN="${FQDN:-default.iam.example.com}"
WORKSPACE="${WORKSPACE:-/opt/workspace/forgeops}"
UPSTREAM="${FR_UPSTREAM:-https://github.com/ForgeRock/forgeops.git}"
DOCKER_REPO="${DOCKER_REPO:-gcr.io/engineering-devops}"
FORK="${FR_FORK}"

usage() {
  cat <<EOF
Usage:
$0 -n namespace -f FQDN -f fork_git_url -d docker_repo dev
    dev  - Create a development skaffold instance for your fully qualified domain name
    init-workspace: clone forgeops and setup directory to work from [-w]
    configure-fork: configure forgeops master to be upstream and origin as fork -f[w]
    render-templates: render kustomization, skaffold, config, dev script -nsdfr[w]
    regenerate-deploy-key: create an ssh key for this pvc for push code on
    run-bootstrap: is to configure-fork and render-templates is run when no cmd is specified

Example:
$0 -n dev -f default.iam.example.com  -r gcr.io/engineering-devops create-dev


EOF
}

setup_workspace() {
  if [[ ! -d "${WORKSPACE}" ]]; then
    echo "Cloning $UPSTREAM"
    git clone --origin upstream --depth 1 "$UPSTREAM" "${WORKSPACE}"
  fi
}

setup_fork() {
  echo "Adding $FORK as the git remote origin"
  if ! git remote add origin "$FORK"; then
    return 1
  fi
  return 0

}

keygen() {
  mkdir -p ~/.ssh "${WORKSPACE}/.ssh"
  ssh-keygen -b 4096 \
    -C "ForgeOps toolbox deployment key" \
    -t ed25519 \
    -f "${WORKSPACE}/.ssh/id_ed"
  cat <<EOF >"$HOME/.ssh/config"
Host *
    IdentityFile $WORKSPACE/.ssh/id_ed
    IdentitiesOnly
EOF
  echo "configure your repo to accept pushes from this public key:"
  cat "${WORKSPACE}/.ssh/id_ed.pub"
  echo ""
  echo ""
  echo "this key is destroyed with the PVC, its recommended that this key be configured with limited access like a deploy key: https://developer.github.com/v3/guides/managing-deploy-keys/"
}

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
    FQDN: $FQDN
    # This uses a cert-manager Let's encrypt issuer. Comment this out if you are not using cert-manager and LE
    CERT_ISSUER: letsencrypt-prod
EOF

  echo "Creating $CDIR/run.sh script"
  cat >"$CDIR/run.sh" <<EOF
#!/usr/bin/env bash
# Generated script - edit for your requirements

# This copies the default (CDK) configuration to the docker/folders.
./bin/config.sh init

# Specify the skaffold profile to use with -p
# dev - use the docker builder profile
# kdev - the Kaniko in-cluster builder.
skaffold --default-repo=$DOCKER_REPO -p kdev dev

EOF
  chmod +x $CDIR/run.sh


  echo "Configuration created in ./dev. YOU MUST EDIT THESE FILES FIRST"
  echo "Edit the run.sh"

}

run_setup_workspace() {
  if [[ "${WORKSPACE}" == "" ]]; then
    echo "workspace required"
    return 1
  fi
  setup_workspace
  return $!

}

run_bootstrap() {
  echo "bootstrapping"
  setup_workspace &&
    run_setup_fork &&
    run_render_templates &&
    touch "${WORKSPACE}/.CONFIGURED"
  return $!
}

run_setup_fork() {
  cd "$WORKSPACE" || return 1
  setup_fork
  return $!
}

run_keygen() {
  if [[ ! -d "${WORKSPACE}/.ssh" ]]; then
    echo "generating ssh key...please provide passphrase"
    keygen
    return $!
  fi
  echo "ssh key already generated, rm -rf ${WORKSPACE}/.ssh to replace it"
  return 1
}

# dont do anything if workspace has been configured
if [[ -f "${WORKSPACE}/.CONFIGURED" ]]; then
  echo "project already bootstrapped"
  exit 0
fi

# handle opts
while getopts n:f:g:d:h option; do
  case "${option}" in

  n) NAMESPACE=${OPTARG} ;;
  f) FQDN=${OPTARG} ;;
  g) UPSTREAM=${OPTARG} ;;
  d) DOCKER_REPO=${OPTARG} ;;
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


while (("$#")); do
  case "$1" in
  init-workspace)
    shift
    run_setup_workspace
    exit $!
    ;;
  configure-fork)
    shift
    run_setup_fork
    exit $!
    ;;
  dev)
    create_dev_config
    exit 0
    ;;
  regenerate-deploy-key)
    run_keygen
    exit 0
    ;;
  run-bootstrap)
    run_bootstrap
    exit $!
    ;;
  *)
    usage
    exit 1
    ;;
  esac
done

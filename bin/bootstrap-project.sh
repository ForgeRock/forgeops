#!/usr/bin/env bash
# This is EXPERIMENTAL (unsupported) and will be replaced by a more robust mechanism in the future.
# It is used internally in ForgeRock to help developers share a cluster.

set -o pipefail

[[ "${FR_DEBUG}" == true ]] && set -x

NAMESPACE="${FR_NAMESPACE}"
SUBDOMAIN="${FR_SUBDOMAIN:-iam}"
DOMAIN="${FR_DOMAIN}"
WORKSPACE="${FR_WORKSPACE:-/opt/workspace/forgeops}"
UPSTREAM="${FR_UPSTREAM:-https://github.com/ForgeRock/forgeops.git}"
DOCKER_REPO="${FR_DOCKER_REPO}"
FORK="${FR_FORK}"

usage() {
    cat <<EOF
Usage:
$0 -n namespace -s subdomain -d domain -f fork_git_url -r docker_repo [-w workspace_dir] init-workspace|configure-fork|render-templates|regenerate-deploy-key
    init-workspace: clone forgeops and setup directory to work from [-w]
    configure-fork: configure forgeops master to be upstream and origin as fork -f[w]
    render-templates: render kustomization, skaffold, config, dev script -nsdfr[w]
    regenerate-deploy-key: create an ssh key for this pvc for push code on
    run-bootstrap: is to configure-fork and render-templates is run when no cmd is specified

Example:
$0 -n dev -s iam -d forgeops.com -f https://github.com/forgerock/forgeops.git -r gcr.io/engineering-devops


EOF
}

setup_workspace () {
    if [[ ! -d "${WORKSPACE}" ]];
    then
        echo "Cloning $UPSTREAM"
        git clone --origin upstream --depth 1 "$UPSTREAM" "${WORKSPACE}"
    fi
}

setup_fork () {
    echo "Adding $FORK as the git remote origin"
    if ! git remote add origin "$FORK";
    then
        return 1
    fi
    return 0

}

keygen () {
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

render_templates () {
    CDIR=./dev
    echo "Generating Kustomize template in $CDIR directory for $NAMESPACE.$SUBDOMAIN.$DOMAIN"
    mkdir -p "$CDIR"
    cat <<EOF >"$CDIR/kustomization.yaml"
# Generated Kustomization file. You may have to edit this for your requirements.
# This deploys to $NAMESPACE.$SUBDOMAIN.$DOMAIN
# for self signed SSL certs. It is suitable for local minikube development
namespace: $NAMESPACE
resources:
- ../kustomize/base/kustomizeConfig
- ../kustomize/base/forgeops-secrets
- ../kustomize/base/7.0/ingress
- ../kustomize/base/7.0/ds/cts
- ../kustomize/base/7.0/ds/idrepo
- ../kustomize/base/am
- ../kustomize/base/amster
- ../kustomize/base/idm
- ../kustomize/base/login-ui
- ../kustomize/base/admin-ui
- ../kustomize/base/end-user-ui

configMapGenerator:
- name: platform-config
  # The env vars below can be passed into a pod using the envFrom pod spec.
  # These global variables can be used to parameterize your deployments.
  # The FQDN and URLs here should match your ingress or istio gateway definitions
  literals:
  - FQDN=$FQDN
  - SUBDOMAIN=$SUBDOMAIN
  - DOMAIN=$DOMAIN
  - AM_URL=https://$FQDN/am
  - IDM_ADMIN_URL=https://$FQDN/admin
  - IDM_UPLOAD_URL=https://$FQDN/upload
  - IDM_EXPORT_URL=https://$FQDN/export
  - PLATFORM_ADMIN_URL=https://$FQDN/platform
  - IDM_REST_URL=https://$FQDN/openidm
  - ENDUSER_UI_URL=https://$FQDN/enduser
  - LOGIN_UI_URL=https://$FQDN/login/#/service/Login
  - ENDUSER_CLIENT_ID=endUserUIClient
  - ADMIN_CLIENT_ID=idmAdminClient
  - THEME=default

# Patches the ingress to use the Let's Encrypt issuer
patchesJson6902:
- target:
    group: extensions
    version: v1beta1
    kind: Ingress
    name: forgerock
  patch: |-
    - op: replace
      path: /metadata/annotations/certmanager.io~1cluster-issuer
      value: letsencrypt-prod
      # value: default-issuer  # Default

vars:
- name: DOMAIN
  fieldref:
    fieldPath: data.DOMAIN
  objref:
    apiVersion: v1
    kind: ConfigMap
    name: platform-config
- name: SUBDOMAIN
  fieldref:
    fieldPath: data.SUBDOMAIN
  objref:
    apiVersion: v1
    kind: ConfigMap
    name: platform-config
- name: NAMESPACE
  objref:
    apiVersion: v1
    kind: ConfigMap
    name: platform-config
  fieldref:
    fieldpath: metadata.namespace
EOF

echo "Creating $CDIR/run.sh script"
cat >"$CDIR/run.sh" <<EOF
#!/usr/bin/env bash
# Generated script

skaffold --default-repo=$DOCKER_REPO -p kdev dev

EOF
chmod +x $CDIR/run.sh

./bin/config.sh -p "$PROFILE" init;
}

run_render_templates () {
    # check required variables
    missing_opts=0
    for req in NAMESPACE SUBDOMAIN DOMAIN WORKSPACE DOCKER_REPO;
    do
        if [[ "${!req}" == "" ]];
        then
            echo "${req} is required";
            missing_opts=1
        fi
    done
    if (( "${missing_opts}" != 0 ));
    then
        usage;
        return 1
    fi
    render_templates
    return $!
}

run_setup_workspace () {
    if [[ "${WORKSPACE}" == "" ]]
    then
        echo "workspace required"
        return 1
    fi
    setup_workspace
    return $!

}

run_bootstrap() {
    echo "bootstrapping"
    setup_workspace \
        && run_setup_fork \
            && run_render_templates \
                && touch "${WORKSPACE}/.CONFIGURED"
    return $!
}

run_setup_fork() {
    cd "$WORKSPACE" || return 1
    setup_fork
    return $!
}

run_keygen () {
    if [[ ! -d "${WORKSPACE}/.ssh" ]];
    then
        echo "generating ssh key...please provide passphrase"
        keygen
        return $!
    fi
    echo "ssh key already generated, rm -rf ${WORKSPACE}/.ssh to replace it"
    return 1
}

# dont do anything if workspace has been configured
if [[ -f "${WORKSPACE}/.CONFIGURED" ]];
then
    echo "project already bootstrapped";
    exit 0
fi

# handle opts
while getopts n:s:d:f:r:w:h option
do
    case "${option}"
        in
        n) NAMESPACE=${OPTARG};;
        s) SUBDOMAIN=${OPTARG};;
        d) DOMAIN=${OPTARG};;
        f) FORK=${OPTARG};;
        r) DOCKER_REPO=${OPTARG};;
        w) WORKSPACE=${OPTARG};;
        h) usage; exit 0;;
        *) usage; exit 1;;
    esac
done
shift $((OPTIND - 1))

FQDN="$NAMESPACE.$SUBDOMAIN.$DOMAIN"
PROFILE="cdk"

while (( "$#" )); do
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
        render-templates)
            run_render_templates
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

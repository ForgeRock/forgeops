#!/usr/bin/env bash
# This is EXPERIMENTAL (unsupported) and will be replaced by a more robust mechanism in the future.
# It is used internally in ForgeRock to help developers share a cluster.
#
# Generates a project skeleton kustomize and skaffold files.
# Usage: init-project.sh namespace domain
#
# For example, running:
# init-project.sh prod acme.com
# Will create a kustomize file to deploy the stack to prod.iam.acme.com
# The project files will in the dev/ directory (in .gitignore)
#
# Domain defaults to forgeops.com if not provided.
#
#
# Top level arguments
NAMESPACE="$1"

DOMAIN="${2:-forgeops.com}"
PROFILE="cdk"
# This is ForgeRock's developer repo. Replace this with your own.
DOCKER_REPO="${DOCKER_REPO:-gcr.io/engineering-devops}"
SUBDOMAIN="iam"

FQDN="$NAMESPACE.$SUBDOMAIN.$DOMAIN"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd "$DIR/.." || exit 1


usage() {
    cat <<EOF
Usage:
$0 namespace [domain]

example:
$0 prod acme.com
EOF
exit 1

}
if [ "$#" -gt 2 ]; then
    usage
fi
if [ -z "$DOMAIN" ] | [ -z "$NAMESPACE" ]; then
  usage
fi

CDIR=./dev

echo "Generating Kustomize template in $CDIR directory for $NAMESPACE.iam.$DOMAIN"

mkdir -p "$CDIR"

cat <<EOF >"$CDIR/kustomization.yaml"
# Generated Kustomization file. You may have to edit this for your requirements.
# This deploys to $NAMESPACE.$SUBDOMAIN.$DOMAIN
# for self signed SSL certs. It is suitable for local minikube development
namespace: $NAMESPACE
resources:
- ../kustomize/base/kustomizeConfig
- ../kustomize/base/forgeops-secrets
- ../kustomize/base/ingress
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
      path: /metadata/annotations/certmanager.k8s.io~1cluster-issuer
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


echo "Generating $CDIR/skaffold.yaml file"

# TODO: There is nothing here that needs to be templated. We could just copy from a skeleton
# We could have it generate partial configs.. (only AM, etc)
cat >"$CDIR/skaffold.yaml" <<EOF
apiVersion: skaffold/v1beta12
kind: Config

# Default profile
build:
  artifacts:
  - image: am
    context: ../docker/7.0/am
  - image: amster
    context: ../docker/7.0/amster
  - image: idm
    context: ../docker/7.0/idm
  - image: ds-cts
    context: ../docker/7.0/ds/cts
  - image: ds-idrepo
    context: ../docker/7.0/ds/idrepo
  - image: forgeops-secrets
    context: ../docker/forgeops-secrets
  tagPolicy:
    sha256: {}
deploy:
  kustomize:
    path: ./
EOF

echo "Initializing the configuration with the $PROFILE profile"
./bin/config.sh -p "$PROFILE" init

echo "Creating $CDIR/run.sh script"
cat >"$CDIR/run.sh" <<EOF
#!/usr/bin/env bash
# Generated script

kubectl config set-context --current --namespace=$NAMESPACE

skaffold --default-repo=$DOCKER_REPO dev

echo "Remember to run ../bin/clean.sh to clean up your PVCs!"
EOF
chmod +x $CDIR/run.sh

cat <<EOF
Environment is ready. To run
cd $CDIR
Run skaffold using minikube:

skaffold dev

Run skaffold with an external repo:
skaffold --default-repo=$DOCKER_REPO dev

For your convenience a run.sh script has been generated
EOF
# Environment settings for the deployment

# k8s namespace to deploy in
NAMESPACE=minikube

# Top level domain. Do not include the leading .
DOMAIN="forgeops.com"

# The components to deploy
# Note the opendj stores are aliased as configstore, userstore, ctstore - but they all use the ds helm chart.
COMPONENTS=(web frconfig  openig)

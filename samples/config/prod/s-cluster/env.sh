# Environment settings for the deployment

# The URL prefix for openam service
URL_PREFIX="openam"

# k8s namespace to deploy in
NAMESPACE="prod"

# Top level domain. Do not include the leading .
DOMAIN="frk8s.net"

# The components to deploy
# Note the opendj stores are aliased as configstore, userstore, ctstore - but they all use the opendj chart.
COMPONENTS=(frconfig configstore userstore openam amster)

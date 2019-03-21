# Environment settings for the deployment

# k8s namespace to deploy in
NAMESPACE=mini

# Top level domain. Do not include the leading .
#DOMAIN="forgeops.com"
DOMAIN=example.com

# The components to deploy
# Note the opendj stores are aliased as configstore, userstore, ctstore - but they all use the opendj chart.
COMPONENTS=(frconfig configstore openam amster postgres-openidm openig openidm web)


# Environment settings for the deployment

# Set the URL_PREFIX and DOMAIN from common.yaml
while read line
do
    if [[ "$line" =~ ^fqdn:.*$ ]]; then 
    	FQDN=${line#fqdn:}
    fi

    if [[ "$line" =~ ^domain:.*$ ]]; then 
    	DOMAIN=${line#domain:}
    fi
done < common.yaml

# The URL prefix for openam service
# You can override by just providing a string here
URL_PREFIX=${FQDN%%.*}

# k8s namespace to deploy in.
NAMESPACE="prod"

# Top level domain. Do not include the leading ".""
# You can override by just providing a string here 
DOMAIN=${DOMAIN/\./}

# The components to deploy
# Note the opendj stores are aliased as configstore, userstore, ctstore - but they all use the opendj chart.
COMPONENTS=(frconfig configstore userstore ctsstore openam amster)

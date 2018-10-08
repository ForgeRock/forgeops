#!/usr/bin/env bash

# Currently, AM config exported through Amster doesn't retain commons parameters.  
# This script can be used to update the exported config with the commons parameters currently available in forgeops.
# Use the variables below to provide the current amsterVersion and fqdn values used in the exported config.  
# This is mandatory for the script to work correctly. 
# - fqdn can be found in site1.json.
# - amsterVersion is available in every config file.
# There is an additional fix at the bottom to resolve a bug in the current export job.


# Variables to be replaced
CURRENT_VERSION="6.5.0-M7" # amsterVersion in config
CURRENT_FQDN="openam.small.lbk8s.net" # fqdn in config

if [ ! -d "global" ]; then
    echo "No global config directory.  Please cd into the relevant config directory. There should be a global/ and realm/ sub directory only"
    exit 9999
fi

# Add version parameter
find . -name "*.json" -exec sed -i '' "s/${CURRENT_VERSION}/\&{version}/g" {} \;

# Add fqdn parameter
find . -name "*.json" -exec sed -i '' "s/${CURRENT_FQDN}/\&{fqdn}/g" {} \;

# Add global ctsstores parameter
sed -i '' 's/"org.forgerock.services.cts.store.directory.name" : "[^"][^"]*"/"org.forgerock.services.cts.store.directory.name" : "\&{CTS_STORES|ctsstore-0.ctsstore:1389}"/g' global/DefaultCtsDataStoreProperties.json

# Add global cts password parameter
sed -i '' 's/"org.forgerock.services.cts.store.password" : null/"org.forgerock.services.cts.store.password" : "\&{CTS_PASSWORD|password}"/g' global/DefaultCtsDataStoreProperties.json

# remove id field for site1.json as this is a bug and import will fail otherwise.
sed -i '' '/"id"/d' global/Sites/site1.json


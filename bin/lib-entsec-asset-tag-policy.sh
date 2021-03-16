#!/usr/bin/env bash

# Generate a templated profile.
function FRProfileTempate () {
    fo_env=${FO_ENV:-env}
    if [[ -f $HOME/.forgeops.${FO_ENV}.sh ]];
    then
        echo "$HOME/.forgeops.${FO_ENV}.sh found refusing to overwrite"
        return 1
    fi
cat <<-EOF > $HOME/.forgeops.${FO_ENV}.sh
# ForgeOps Profile
# forgeops_profile_version=v0.0.1
#
# This file is sourced by cluster-up.sh scripts to set asset tags required
# by EntSec team.
# The profile can also be merged with some or all of the variables CDM size
# scripts eg. small.sh
# This file's name should be ~/.forgeops.${FO_ENV}.sh
# Set the FO_ENV environment variable when running cluster-up.sh to use/create a specific profile.

# Where to get help?
# For questions around values, policy, why was my cluster deleted see #enterprise-security
# For question about  see
# For bugs and script issues #cloud-deployment

export IS_FORGEROCK=yes

# User email which might be used to contact you.
# Note:
#    - all lower case
#    - , _ for .
#    - just the username of the email
# e.g. ES_USEREMAIL=david_goldsmith
export ES_USEREMAIL=unset
# Obtains the priority and lifetime set by EntSec.
# production,preproduction,development,sandbox,ephemeral
export ES_ZONE=unset
# UK/US/AJP
export BILLING_ENTITY=unset
# Determines the party responsible for the asset.
# university,tpp,supsus,sales,sa,openbanking,marketing,fraas,it,engineering,entsec,dss,ctooffice,backstage,autoeng,am-engineering
export ES_BUSINESSUNIT=unset
# These two can be more grainular or just the same as ES_BUSINESSUNIT
# but deviations supposed to set up with EntSec
export ES_OWNEDBY=unset
export ES_MANAGEDBY=unset
EOF

}
# If FR user doesn't meet tag rules return 1
function EnforceEntSecTags () {
    # Do nothing for non ForgeRockers
    if [[ "$IS_FORGEROCK" == "no" ]];
    then
        return
    fi
    # FR should have gcloud installed or the forgeops env file
    ES_USEREMAIL=${ES_USEREMAIL:-"unset"}
    ES_ZONE=${ES_ZONE:-"unset"}
    ES_BUSINESSUNIT=${ES_BUSINESSUNIT:-"unset"}
    BILLING_ENTITY=${BILLING_ENTITY:-"unset"}
    ES_OWNEDBY=${ES_OWNEDBY:="unset"}
    ES_MANAGEDBY=${ES_MANAGEDBY:="unset"}
    if [[ "$IS_FORGEROCK" == "yes" ]];
    then
       [[ "$ES_MANAGEDBY" != "unset" ]] \
        &&  [[ "$ES_USEREMAIL" != "unset" ]] \
        &&  [[ "$ES_BUSINESSUNIT" != "unset" ]] \
        && [[ "$BILLING_ENTITY" != "unset" ]] \
        && [[ "$ES_OWNEDBY" != "unset" ]] \
        && [[ "$ES_MANAGEDBY" != "unset" ]] \
        && return \
        || return 1
    fi
}

# Prompt user if required, return yes for ForgeRock
function IsForgeRock() {
    IS_FORGEROCK=${IS_FORGEROCK:-unset}
    # Check for override
    if [[ "$IS_FORGEROCK" == "no" ]] || [[ -f ~/.forgeops.noop.sh ]];
    then
        echo "no"
        return
    fi
    # Follow the env profile, a profile means this is a ForgeRock employee
    fo_env=${FO_ENV:-env}
    if [[ -f $HOME/.forgeops.${fo_env}.sh ]];
    then
        echo "yes"
        return
    fi
    if [[ "$IS_FORGEROCK" == "unset" ]];
    then
        question="ForgeRock staff are required to provide metadata.
Are you a ForgeRock employee?[y/n]"
        read -p "$question " is_fr
        while true
        do
            case $is_fr in
                [yY])
                    echo "yes"
                    FRProfileTempate
                    return;;
                [nN])
                    echo "no"
                    touch ~/.forgeops.noop.sh
                    return;;
                *)
                    echo "invalid"
                    return 1;;
            esac
        done
    fi
}

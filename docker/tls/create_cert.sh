#!/usr/bin/env bash

# Variables
FQDN="*.${NAMESPACE}.forgeops.com" # FQDN for self signed cert based on namespace
PRODUCT=(openig openidm openam) # FR product Array

# Set exit options
exit_script() {
    echo "Got signal. Killing child processes"
    trap - SIGINT SIGTERM # clear the trap
    kill -- -$$ # Sends SIGTERM to child/sub processes
    echo "Exiting"
    exit 0
}

trap exit_script SIGINT SIGTERM SIGUSR1 EXIT

# Delete any certificate jobs from previous deployments
delete_old_jobs () {

    for i in ${PRODUCT[@]}; do
        if [[ $(kubectl get jobs tls-generator-${i} -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}') == True ]]; then
            kubectl delete job tls-generator-${i}
        fi   
    done
}

# Create a self-signed certificate
create_selfsigned () {
    openssl req \
       -newkey rsa:2048 -nodes -keyout tls.key \
       -x509 -days 365 -out tls.crt \
       -subj "/C=US/ST=California/L=San Francisco/O=ForgeRock/CN=${FQDN}"
    # Create tls secret
    kubectl create secret tls wildcard.${NAMESPACE}.forgeops.com --cert=./tls.crt --key=./tls.key
    # Add label to secret
    kubectl label secret wildcard.lee.forgeops.com strategy=SelfSigned
}

# Delete old tls generator jobs
delete_old_jobs

if [[ $(kubectl get secret --no-headers wildcard.${NAMESPACE}.forgeops.com | awk '{print $1}') ]]; then
    printf "\n*** TLS secret already exists ***\n"
    case "$(kubectl get secret wildcard.${NAMESPACE}.forgeops.com -o=jsonpath='{.metadata.labels.strategy}')" in
        "" ) 
            printf "Current tls secret is provided by CertManager\n" ;;
        SelfSigned ) 
            printf "Current tls secret is SelfSigned\n"  ;;
        UserProvided ) 
            printf "Current tls secret is UserProvided\n"  ;;
    esac
    printf "If you want to change the TLS strategy for all FR products, run: \n"
    printf "* kubectl delete secret wildcard.${NAMESPACE}.forgeops.com\n"
    printf "* redeploy product\n"
else
    # Create secret based on self-signed or user provided tls certs
    case "$STRATEGY" in
        SelfSigned ) 
            create_selfsigned 
            ;;
        UserProvided ) 
            kubectl create secret tls wildcard.${NAMESPACE}.forgeops.com --cert=/certs/tls.crt --key=/certs/tls.key 
            kubectl label secret wildcard.lee.forgeops.com strategy=UserProvided
            ;;
    esac
fi;

sleep 5

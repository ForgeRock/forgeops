#!/usr/bin/env bash
# Script can be used to either automatically generate a self-signed TLS certificate, or to provide your own TLS cert and key.
# Either method will be wrapped up in a secret called wildcard.<namespace>.<domain> which is inherited by the ingress and can be used by all FR products.

# ***IMPORTANT***  the following value must be set in your custom.yaml:
# useCertManager: false
# otherwise the deployment will try to generate a certmanager certificate object and will override the secret if certmanager is installed.
# Copy the etc/generate-tls.template file to etc/generate-tls.cfg and specify your values as required.

echo "=> Have you copied the template file etc/generate-tls.template to etc/generate-tls.cfg and edited to cater to your requirement?"
read -p "Continue (y/n)?" choice
case "$choice" in 
   y|Y|yes|YES ) echo "yes";;
   n|N|no|NO ) echo "no"; exit 1;;
   * ) echo "Invalid input, Bye!"; exit 1;;
esac

. ../etc/generate-tls.cfg

FQDN="*.${NAMESPACE}.${DOMAIN}" # FQDN for self signed cert based on namespace

# Create a self-signed certificate
create_selfsigned () {
    openssl req \
       -newkey rsa:2048 -nodes -keyout tls.key \
       -x509 -days 365 -out tls.crt \
       -subj "/C=US/ST=California/L=San Francisco/O=ForgeRock/CN=${FQDN}"
    # Create tls secret
    kubectl create secret tls wildcard.${NAMESPACE}.${DOMAIN} --cert=./tls.crt --key=./tls.key
    # Add label to secret
    kubectl label secret wildcard.${NAMESPACE}.${DOMAIN} strategy=SelfSigned
    # Clean up
    rm tls.crt tls.key
}

# Create a self-signed or user provided certificate
create_secret () {
    # Create secret based on self-signed or user provided tls certs
    case "$STRATEGY" in
        SelfSigned ) 
            create_selfsigned 
            ;;
        UserProvided ) 
            kubectl create secret tls wildcard.${NAMESPACE}.${DOMAIN} --cert=$CERT_PATH --key=$KEY_PATH 
            kubectl label secret wildcard.${NAMESPACE}.${DOMAIN} strategy=UserProvided
            ;;
    esac
}

# Check if a certificate secret already exists
if [[ $(kubectl get secret --no-headers wildcard.${NAMESPACE}.${DOMAIN} | awk '{print $1}') ]]; then
    printf "\n*** TLS secret already exists ***\n"
    case "$(kubectl get secret wildcard.${NAMESPACE}.${DOMAIN} -o=jsonpath='{.metadata.labels.strategy}')" in
        "" ) 
            printf "Current tls secret is provided by CertManager\n" ;;
        SelfSigned ) 
            printf "Current tls secret is SelfSigned\n"  ;;
        UserProvided ) 
            printf "Current tls secret is UserProvided\n"  ;;
    esac
    
    # Ask user if they would like to delete the secret and create new secret
    read -p "Would you like to delete the TLS secret and create a new ${STRATEGY} secret? [Y/N] " -n 1 -r
    echo   
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
        kubectl delete secret wildcard.${NAMESPACE}.${DOMAIN}
        create_secret
        exit
    fi
    
    printf "** No new TLS secret has been created **\n"
else
    # Create secret
    create_secret
fi;


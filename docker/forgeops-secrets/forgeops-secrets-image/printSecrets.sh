#!/bin/bash

getsec () {
    kubectl get secret $1 -o jsonpath="{.data.$2}" | base64 -d
}

case $1 in 
    "6.5")
        echo "         CN=Directory Manager: $(getsec ds dirmanager\\.pw)"
    ;;
    "7.0")
        echo "                    uid=admin: $(getsec ds-passwords dirmanager\\.pw)"
    ;;
    *)
        echo "NOTE: You must run this script with a version number to get all credentials, eg."
        echo "./printSecrets.sh 6.5"
        echo "or"
        echo "./printSecrets.sh 7.0"
    ;;
esac

        echo ""  
        echo "config store profile password: $(getsec amster-env-secrets CFGUSR_PASS)"
        echo "   cts store profile password: $(getsec amster-env-secrets CTSUSR_PASS)"
        echo "      idrepo profile password: $(getsec amster-env-secrets USRUSR_PASS)"
        echo ""
        echo "             amadmin password: $(getsec amster-env-secrets AMADMIN_PASS)"
        echo "       openidm-admin password: $(getsec idm-env-secrets OPENIDM_ADMIN_PASSWORD)"
        echo ""
        echo "   To backup your generated secrets, run the following kubectl command:"
        echo "   kubectl get secret -lsecrettype=forgeops-generated -o yaml > secrets.yaml"
        echo ""
        echo "   To restore backed up secrets, run the following kubectl command:"
        echo "   kubectl apply -f secrets.yaml"
        echo ""
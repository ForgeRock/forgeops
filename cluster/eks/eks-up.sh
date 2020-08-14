#!/usr/bin/env bash
# Provision EKS cluster using eksctl
# ./e

set -o errexit
set -o pipefail
set -o nounset

usage() {
    printf "\nUsage: $0 <create|delete> <config file>\n\n"
}

# Create cluster
create_cluster() {
    eksctl create cluster -f ${file}

    # Who created this cluster.
    CREATOR="${USER:-unknown}"
    # Labels can not contain dots that may be present in the user.name
    CREATOR=$(echo $CREATOR | sed 's/\./_/' | tr "[:upper:]" "[:lower:]")

    kubectl label nodes -l alpha.eksctl.io/nodegroup-name=primary new-label=$CREATOR
    kubectl label nodes -l alpha.eksctl.io/nodegroup-name=ds new-label=$CREATOR
}

# Create IAM role mappings
createIAMMapping() {
    eksctl create iamidentitymapping --cluster $cluster_name $role-arn --group system:masters --group cdm-users
}

createStorageClasses() {
    kubectl create -f - <<EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
    name: fast
provisioner: kubernetes.io/aws-ebs
parameters:
    type: gp2
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
    name: standard
provisioner: kubernetes.io/aws-ebs
parameters:
    type: gp2
EOF

    # Set default storage class to 'fast'
    kubectl patch storageclass fast -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

    # Delete gp2 storage class
    kubectl delete storageclass gp2
}

if [[ "$#" -eq 2 ]]; then
    # Get values from yaml file
    cluster_name=$(grep -A1 '^metadata:$' $2 | tail -n1 | awk '{ print $2 }')
    region=$(grep -A2 'metadata:' $2 | tail -n1 | awk '{ print $2 }')

    # Check if yaml file exists
    if test -f "$2"; then
        echo "$2 exists."
        file=$2
    else    
        printf "\nProvided config file name doesn't exist\n\n"
    fi
    case $1 in 
            "create")
                echo "Creating EKS cluster..."
                eksctl create cluster -f ${file}
                #echo "Creating identity mappings..."
                # createIAMMapping
                echo "Creating storage classes..."
                createStorageClasses
                echo "Creating prod namespace..."
                kubectl create ns prod
            ;;

            "delete")
                echo "Deleting cluster ${cluster_name}..."
                eksctl delete cluster --name $cluster_name --wait
            ;;

            *)
                usage
                exit 1;
            ;;
    esac
else
    usage
    exit 1 
fi
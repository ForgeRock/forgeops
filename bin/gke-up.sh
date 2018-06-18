#!/usr/bin/env bash
# Sample wrapper script to initialize GKE. This creates the cluster and configures Helm, the nginx ingress,
# and creates git credential secrets. Edit this for your requirements.

echo "=> Have you copied the template file etc/gke-env.template to etc/gke-env.cfg and edited to cater to your enviroment?"
read -p "Continue (y/n)?" choice
case "$choice" in 
   y|Y|yes|YES ) echo "yes";;
   n|N|no|NO ) echo "no"; exit 1;;
   * ) echo "Invalid input, Bye!"; exit 1;;
esac

. ../etc/gke-env.cfg

./create-cluster.sh

if [ $? -ne 0 ]; then
    exit 1 
fi

./gke-create-nodepool.sh 

kubectl create namespace $GKE_CLUSTER_NS
kubectl config set-context $(kubectl config current-context) --namespace=$GKE_CLUSTER_NS
./create-sc.sh
./helm-rbac-init.sh

# Need as sometimes tiller is not ready immediately
while :
do
    helm ls >/dev/null 2>&1
    test $? -eq 0 && break
    echo "Waiting on tiller to be ready..."
    sleep 5s
done

./create-nfs-provisioner.sh

./gke-ingress-cntlr.sh $GKE_INGRESS_IP

# Add cert-manager
./deploy-cert-manager.sh

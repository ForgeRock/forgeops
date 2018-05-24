#!/usr/bin/env bash
# Sample wrapper script to initialize GKE. This creates the cluster and configures Helm, the nginx ingress,
# and creates git credential secrets. Edit this for your requirements.

echo "=> Have you copied the template file etc/gke-env.template to etc/gke-env.cfg and edited to cater to your enviroment?"
read -p "Continue (y/n)?" choice
case "$choice" in 
   y|Y|yes|YES ) echo "yes";;
   n|N|no|NO ) echo "no"; exit;;
   * ) echo "Invalid input, Bye!"; exit;;
esac

. ../etc/gke-env.cfg

./create-cluster.sh
kubectl create namespace $GKE_CLUSTER_NS
kubectl config set-context $(kubectl config current-context) --namespace=$GKE_CLUSTER_NS
./create-sc.sh
./helm-rbac-init.sh
# Need this sleep as tiller is not ready immediately
sleep 20s
./gke-ingress-cntlr.sh $GKE_INGRESS_IP
./create-nfs-provisioner.sh
# Add cert-manager
./deploy-cert-manager.sh

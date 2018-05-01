#!/usr/bin/env bash
# Sample wrapper script to initialize GKE. This creates the cluster and configures Helm, the nginx ingress,
# and creates git credential secrets. Edit this for your requirements.

echo "=> Have you copied the template file gke-env.template to gke-env.cfg and edited to cater to your enviroment?"
read -p "Continue (y/n)?" choice
case "$choice" in 
   y|Y|yes|YES ) echo "yes";;
   n|N|no|NO ) echo "no"; exit;;
   * ) echo "Invalid input, Bye!"; exit;;
esac

. ../etc/gke-env.cfg

./create-cluster.sh
./create-sc.sh
kubectl create namespace $GKE_CLUSTER_NS
./helm-rbac-init.sh
./create-secrets.sh
# Need this sleep as tiller is not ready immediately
sleep 10s
./gke-ingress-cntlr.sh $GKE_INGRESS_IP

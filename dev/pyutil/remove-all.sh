#!/usr/bin/env bash
echo "Deleting all skaffold deployments and PVCs"
skaffold delete -f am/skaffold.yaml
skaffold delete -f amster/skaffold.yaml
skaffold delete -f skaffold-db.yaml
skaffold delete -f idm/skaffold.yaml
skaffold delete -f ig/skaffold.yaml
cd pyutil
skaffold delete 
kubectl delete pvc --all
cd ..
echo "Done"

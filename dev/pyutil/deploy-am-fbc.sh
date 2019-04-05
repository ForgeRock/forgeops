#!/usr/bin/env bash
skaffold delete -f skaffold-db.yaml
kubectl delete pvc --all
skaffold run -f skaffold-db.yaml
cd am
skaffold delete
skaffold run
cd ../pyutil
skaffold delete
skaffold -p runtime-cfg dev

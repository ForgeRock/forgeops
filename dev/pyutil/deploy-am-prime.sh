#!/usr/bin/env bash
echo "Deploying AM with prime profile"
echo "Will deploy pyutil to do initial AM configuration"
cd am
skaffold run -p prime 
cd ..
skaffold run -f skaffold-db.yaml
cd pyutil
skaffold dev
cd ..
echo "Done. Watch <kubectl logs -f pyutil> for configuration progress"
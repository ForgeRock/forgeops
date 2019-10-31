#!/usr/bin/env bash
#!/usr/bin/env bash
# Triggers an amster export, then copies the results to the tmp/ directory
# Use this to capture configuration.  We suggest you selectively
# copy file from the export into the config directory
# Note that tmp/ is in .gitignore, and is not checked in

rm -fr tmp
pod=`kubectl get pod -l app=amster -o jsonpath='{.items[0].metadata.name}'`

echo "Executing amster export within the amster pod"
kubectl exec $pod -it /opt/amster/export.sh

echo "Copying the export to the ./tmp directory"
kubectl cp $pod:/var/tmp/amster ./tmp


echo "Done"
# clean up non essential files
#rm -fr ./tmp/openam/{log,debug,install.log} ./tmp/openam/am/{log,debug,install.log}


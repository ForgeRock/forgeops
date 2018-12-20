#!/usr/bin/env bash
#
# Simple script to get all logs, descriptions, events from selected namespace.
# Useful for debugging.


# Max lines to print for pod logs
NUM_LINES=400

kcontext=`kubectl config current-context`
NS=`kubectl config view -o jsonpath="{.contexts[?(@.name==\"$kcontext\")].context.namespace}"`

if [ $# = '1' ]; then
    NAMESPACE=$1
else
    NAMESPACE=$NS
fi

echo "Generating debug log for namespace $NAMESPACE"
POD_LIST=$(kubectl -n=${NAMESPACE} get pods -o go-template --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}')

# Go through all pods and get containers for each pod. Get logs from these containers
E_TIME=`date`

mkdir -p /tmp/forgeops
rm -f /tmp/forgeops/*
OUT=/tmp/forgeops/log-template.html

rm -fr $OUT 

# Table of contents for pods
TOC=""

for pod in ${POD_LIST}; do
  echo "Generating $pod logs"
  echo "<h2><a id=\"${pod}\">Pod ${pod} </a></h2>" >> $OUT 

  TOC="$TOC <li><a href=\"#${pod}\">${pod}</a></li>"

  init_containers=$(kubectl -n=${NAMESPACE} get pod ${pod} -o jsonpath='{.spec.initContainers[*].name}' | tr " " "\n")
  containers=$(kubectl -n=${NAMESPACE} get pod ${pod} -o jsonpath='{.spec.containers[*].name}' | tr " " "\n")
  echo "<p>Pod description: </p><pre>" >> $OUT
  kubectl -n=${NAMESPACE} describe pod ${pod} >> $OUT
  echo "</pre><br><p><a href=\"#toc\">Back to Index</a></p>" >> $OUT


  for container in ${init_containers}; do 
      echo "<h3>Logs for init container: $container</h3><br><pre>" >> $OUT
       kubectl -n=${NAMESPACE} logs ${pod} ${container} | head -"$NUM_LINES" >> $OUT
       echo "</pre><br><hr>" >> $OUT 
  done

  for container in ${containers}; do
    echo "<h3>Logs for container: $container</h3><br><pre>" >> $OUT
    kubectl -n=${NAMESPACE} logs ${pod} ${container} | head -"$NUM_LINES" >> $OUT
    echo "</pre><br><hr>" >> $OUT 
  done

done

OBJECT_TOC=""

objects="service ingress configmap secrets"
for object in $objects; do
    echo "<h2><a id=\"$object\">$object</a></h2><br/><pre>" >> $OUT
    kubectl describe $object  >> $OUT

    OBJECT_TOC="$OBJECT_TOC <li><a href=\"#$object\">$object</a></li>"

    echo "</pre><br/><p><a href=\"#toc\">Back to Index</a></p>" >> $OUT
done


FINAL=/tmp/forgeops/log.html


## Create the Header 
cat >$FINAL <<EOF 
<html>
<h1>Debug Output for namespace ${NAMESPACE} taken at $E_TIME</h1>
<br>
<h3><a id="toc">Pod Logs</a></h3>
<ul>
  $TOC
</ul >
<br/>
<h3>Other Objects</h3>
<ul>
    $OBJECT_TOC
</ul>
<hr>
EOF

cat >>$FINAL $OUT

cat >>$OUT <<EOF
</html>
EOF

echo "open file://${FINAL} in your browser"

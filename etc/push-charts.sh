#!/usr/bin/env bash
# Push our charts up to a gs storage bucket for Helm.

cdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

BUCKET=forgerock-charts
URL="https://storage.googleapis.com/forgerock-charts"

hdir=${cdir}/../helm

dir=/tmp/charts

rm -fr $dir
mkdir -p $dir
cd $dir
charts="opendj amster openam openidm openig postgres-openidm frcommon git opendj-git cmp-idm-dj-postgres cmp-am-dj cmp-am-dev cmp-platform cmp-am-embedded"
for chart in $charts
do
    echo "Packaging $chart"
    helm dep update $hdir/$chart
    helm package $hdir/$chart
done

gsutil cp gs://${BUCKET}/index.yaml .
helm repo index --url $URL --merge index.yaml .

gsutil -m rsync ./ gs://${BUCKET}

gsutil -m acl set -R -a public-read gs://${BUCKET}

# See https://github.com/kubernetes/helm/issues/2453.
# This makes sure the bucket is not cached (default is to cache https:// objects for 1 hour).
gsutil -m setmeta -h "Content-Type:text/html" -h "Cache-Control:private, max-age=0, no-transform" "gs://${BUCKET}/*"


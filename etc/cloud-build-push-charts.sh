#!/usr/bin/env bash
# Push our charts up to a gs storage bucket for Helm.
# Runs as a cloud build step, so we need to download helm.

BUCKET=forgerock-charts
URL="https://storage.googleapis.com/forgerock-charts"

# Where our helm charts are located.
hdir=`pwd`/helm


# The previous build step downloaded Helm to our working directory. We need to unpack it.
tar xvf helm.tar.gz

helm=`pwd`/linux-amd64/helm
chmod +x $helm

$helm init --client-only

dir=/tmp/charts

rm -fr $dir
mkdir -p $dir
cd $dir
charts="opendj amster openam openidm openig postgres-openidm frcommon git opendj-git cmp-idm-dj-postgres cmp-am-dj cmp-am-dev cmp-platform cmp-am-embedded"
for chart in $charts
do
    echo "Packaging $chart"
    $helm dep update $hdir/$chart
    $helm package $hdir/$chart
done

# Fetch a copy of the existing index.
gsutil cp gs://${BUCKET}/index.yaml .
# Merge the new charts with the existing index.
$helm repo index --url $URL --merge index.yaml .

# Copy all the charts and index up to our bucket.
gsutil -m rsync ./ gs://${BUCKET}

# Make the charts world readable.
gsutil -m acl set -R -a public-read gs://${BUCKET}

# See https://github.com/kubernetes/helm/issues/2453.
# This makes sure the bucket is not cached (default is to cache https:// objects for 1 hour).
gsutil -m setmeta -h "Content-Type:text/html" -h "Cache-Control:private, max-age=0, no-transform" "gs://${BUCKET}/*"

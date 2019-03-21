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
charts="frconfig ds amster openam openidm openig postgres-openidm web apache-agent"
for chart in $charts
do
    echo "Packaging $chart"
    $helm dep update --skip-refresh $hdir/$chart
    $helm package $hdir/$chart
done

# include the unsupported sample fr-platform chart along with the others
# $helm package $hdir/../samples/fr-platform

# Fetch a copy of the existing index.
gsutil cp gs://${BUCKET}/index.yaml .
# Merge the new charts with the existing index.
$helm repo index --url $URL --merge index.yaml .

# Copy all the charts and index up to our bucket.
gsutil -q -m rsync ./ gs://${BUCKET}

# Make the charts world readable.
gsutil -q -m acl set -R -a public-read gs://${BUCKET}

# See https://github.com/kubernetes/helm/issues/2453.
# This makes sure the bucket is not cached (default is to cache https:// objects for 1 hour).
gsutil -q -m setmeta -h "Content-Type:text/html" -h "Cache-Control:private, max-age=0, no-transform" "gs://${BUCKET}/*"

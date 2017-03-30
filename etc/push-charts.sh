#!/usr/bin/env bash
# Push our charts up to a gs storage bucket for Helm
# You then add this as a Helm repo
cdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

BUCKET=forgerock-charts
URL="https://storage.googleapis.com/forgerock-charts"

hdir=${cdir}/../helm

dir=/tmp/charts

charts="opendj amster openam openidm"

rm -fr $dir
mkdir -p $dir
cd $dir

for chart in $charts
do
    helm package $hdir/$chart
done

helm repo index --url $URL .

cd $cdir

./sync-repo.sh /tmp/charts ${BUCKET}


gsutil -m acl set -R -a public-read gs://${BUCKET}

echo "Adding helm repo"
echo "helm repo add forgerock $URL"

helm repo add forgerock $URL

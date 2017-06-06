#!/usr/bin/env bash
# Push our charts up to a gs storage bucket for Helm
# You then add this as a Helm repo
cdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

BUCKET=forgerock-charts
URL="https://storage.googleapis.com/forgerock-charts"

hdir=${cdir}/../helm

dir=/tmp/charts

rm -fr $dir
mkdir -p $dir
cd $dir
charts="opendj amster openam openidm openig postgres-openidm frcommon git cmp-idm-dj-postgres cmp-am-dj cmp-am-dev"
for chart in $charts
do
    echo "Packaging $chart"
    helm package $hdir/$chart
done

helm repo index --url $URL .

cd $cdir

./sync-repo.sh /tmp/charts ${BUCKET}


gsutil -m acl set -R -a public-read gs://${BUCKET}

# See https://github.com/kubernetes/helm/issues/2453.
gsutil setmeta -h "Content-Type:text/html" \
  -h "Cache-Control:private, max-age=0, no-transform" gs://${BUCKET}


echo "Adding helm repo"
echo "helm repo add forgerock $URL"

helm repo add forgerock $URL


cd $hdir

for d in cmp*
do
    ~/bin/helm dep up $d
done



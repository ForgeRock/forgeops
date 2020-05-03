#!/usr/bin/env bash
# Clean up old GCS images. This is not supported - use at your own risk
set -eo pipefail

images="am idm amster ig ds-idrepo ds-cts"

# Clean all images older than this date
# NOTE: Does not work on macos. Needs Gnu date
DATE=$(date +"%m-%d-%Y" -d "-90 days")
# Cache can be deleted as of today
CACHE_DATE=$(date +"%m-%d-%Y")

for image in $images
do
   ./gcrgc.sh gcr.io/engineering-devops/$image $DATE
    ./gcrgc.sh gcr.io/engineering-devops/$image/cache $CACHE_DATE
done

# smoke and nightly - after 10 days
DATE=$(date +"%m-%d-%Y" -d "-10 days")
for image in $(gcloud container images list --repository gcr.io/engineering-devops/nightly)
do
   ./gcrgc.sh $image $DATE
done

for image in $(gcloud container images list --repository gcr.io/engineering-devops/smoke)
do
   ./gcrgc.sh $image $DATE
done

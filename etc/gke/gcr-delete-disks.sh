#!/usr/bin/env bash
# Delete disks that are not attached to a VM.
# USE WITH CAUTION. Make sure this is really what you want to do.

for d in `gcloud compute disks list --filter="-users:*" --format="csv[no-heading](name,zone)"`;  do
  disk=$(echo $d | cut -d ',' -f1)
  zone=$(echo $d | cut -d ',' -f2)
  echo " Deleting disk $disk in zone $zone"
  gcloud --quiet compute disks delete $disk  --zone $zone
done

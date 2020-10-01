#!/bin/bash
set -euo pipefail

echo "ForgeOPS secrets generation job"
echo "#### GETTING EXISTING SECRETS ####"
./getset.sh -g /opt/gen/secrets secrettype=forgeops-generated
echo "#### GENERATING MISSING SECRETS ####"
./gen.sh /opt/gen/secrets
echo "#### DELETING/RECREATING SECRETS IN CLUSTER ####"
./getset.sh -s /opt/gen/secrets secrettype=forgeops-generated
echo "#### CLEANING UP ####"
rm -Rf /opt/gen/secrets
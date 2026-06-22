#!/usr/bin/env bash
set -euo pipefail
# Grab our starting dir
start_dir=$(pwd)
# Figure out the dir we live in
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ROOT_DIR="$(realpath ${SCRIPT_DIR}/..)"
# Bring in our standard functions
source ${ROOT_DIR}/lib/shell/stdlib.sh
# runOrPrint mandatory variables
DEBUG=false
DRYRUN=false
VERBOSE=false
NUM_ERROR=0

CHARTS=(
  "${ROOT_DIR}/charts/identity-platform"
  "${ROOT_DIR}/charts/ping-gateway"
)

echo ""
echo "-------------------------"
echo "------- helm lint -------"
echo "-------------------------"
echo ""
for chart in "${CHARTS[@]}"; do
  echo "- Checking ${chart}"
  runOrPrint helm lint "${chart}"
  if [ $? -ne 0 ] ; then NUM_ERROR=$((NUM_ERROR+1)) ; fi
  echo ""
done

echo "----------------------------------------------"
echo "------- helm template (default values) -------"
echo "----------------------------------------------"
echo ""
for chart in "${CHARTS[@]}"; do
  echo ""
  echo "- Checking ${chart}"
  runOrPrint helm template release-name "$chart" > /dev/null
  if [ $? -ne 0 ] ; then NUM_ERROR=$((NUM_ERROR+1)) ; fi
done

echo "==> helm template (feature flags: pdb + autoscaling)"
runOrPrint helm template release-name "${ROOT_DIR}/charts/identity-platform" \
  --set am.pdb.enabled=true \
  --set am.autoscaling.enabled=true \
  > /dev/null
  if [ $? -ne 0 ] ; then NUM_ERROR=$((NUM_ERROR+1)) ; fi

echo
if [ ${NUM_ERROR} -eq 0 ] ; then
  echo "==> All Helm validations passed."
  exit 0
else
  echo "==> Found ${NUM_ERROR} errors"
  exit 1
fi
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

echo "==> helm template (OpenShift mode: exposure surface is Routes, not Ingress)"
# platform.ingress.enabled and the ds_set_passwords security contexts are
# deliberately ABSENT from values.yaml (mode-owned under
# platform.openshift.enabled — see the values.yaml comments). This render
# asserts the mode posture: any re-added chart default for those keys
# breaks unset-detection and fails here with Ingress objects in the render.
# (helm is invoked directly, not via runOrPrint, because the stdout must be
# captured for the assertion; runOrPrint evals inline and prints to the
# terminal instead.)
OPENSHIFT_TEMPLATE=$(helm template release-name "${ROOT_DIR}/charts/identity-platform" \
  --set platform.openshift.enabled=true) || NUM_ERROR=$((NUM_ERROR+1))
# grep -c (NOT grep -q): under `set -o pipefail`, grep -q exits on its first
# match and SIGPIPEs the producer mid-stream, turning a SUCCESSFUL match into
# a nonzero pipeline — the assertion would pass on the very defect it exists
# to catch. grep -c reads to EOF, so the pipeline status is trustworthy; the
# || true covers grep's exit 1 when the count is zero.
INGRESS_COUNT=$(printf '%s\n' "${OPENSHIFT_TEMPLATE}" | grep -c '^kind: Ingress') || true
if [ "${INGRESS_COUNT}" -ne 0 ] ; then
  echo "ERROR: platform.openshift.enabled=true must not render Ingress objects (found ${INGRESS_COUNT})."
  echo "  platform.ingress.enabled is mode-owned (platform.ingressEnabled in _helpers.tpl);"
  echo "  a value set in values.yaml (or a sibling values-*.yaml) defeats unset-detection."
  NUM_ERROR=$((NUM_ERROR+1))
else
  echo "==> on-mode render contains no Ingress objects: OK"
fi

echo
if [ ${NUM_ERROR} -eq 0 ] ; then
  echo "==> All Helm validations passed."
  exit 0
else
  echo "==> Found ${NUM_ERROR} errors"
  exit 1
fi
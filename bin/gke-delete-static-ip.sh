#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample script to create a Kubernetes cluster on Google Kubernetes Engine (GKE)
# You must have the gcloud command installed and access to a GCP project.
# See https://cloud.google.com/container-engine/docs/quickstart

CONFIGURATION_FILE="${BASH_SOURCE%/*}/../etc/gke-env.cfg"
if [ ! -f "${CONFIGURATION_FILE}" ] ; then
    echo "ERROR : Configuration file does not exist : ${CONFIGURATION_FILE}"
    exit 1
fi
source "${CONFIGURATION_FILE}"

IP_NAME="${USER}-ip"
REGION=`echo "${GKE_PRIMARY_ZONE}" | sed "s@\(.*\)-[a-z]@\1@g"`
echo ""
echo "=> Deleting ip ..."
echo Y | gcloud compute addresses delete ${IP_NAME} --region ${REGION}
if [ $? -eq 0 ] ; then
    echo "PASS : ip deleted"
else
    echo "ERROR : creating ip"
    exit 1
fi
#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Sample script to create a Kubernetes cluster on Google Kubernetes Engine (GKE)
# You must have the gcloud command installed and access to a GCP project.
# See https://cloud.google.com/container-engine/docs/quickstart

CONFIGURATION_FILE="${BASH_SOURCE%/*}/../etc/gke-env.cfg"
if [ ! -f "${CONFIGURATION_FILE}" ] ; then
    echo "ERROR :Configuration file does not exist : ${CONFIGURATION_FILE}"
    exit 1
fi
source "${CONFIGURATION_FILE}"

IP_NAME="${USER}-ip"
REGION=`echo "${GKE_PRIMARY_ZONE}" | sed "s@\(.*\)-[a-z]@\1@g"`
echo ""
echo "=> Creating ip ..."
gcloud compute addresses create ${IP_NAME} --region ${REGION}
if [ $? -eq 0 ] ; then
    IP_ADDRESS=`gcloud compute addresses describe ${IP_NAME} --region ${REGION} | grep "^address: " | awk -F' ' '{print $2}'`
    echo "name    : ${IP_NAME}"
    echo "region  : ${REGION}"
    echo "address : ${IP_ADDRESS}"
else
    echo "ERROR : creating ip"
    exit 1
fi

echo ""
echo "=> update GKE_INGRESS_IP variable accordingly in ${CONFIGURATION_FILE}"
sed "s@GKE_INGRESS_IP=\(.*\)@GKE_INGRESS_IP=\"$IP_ADDRESS\"@" ${CONFIGURATION_FILE} > ${CONFIGURATION_FILE}.new
mv ${CONFIGURATION_FILE}.new ${CONFIGURATION_FILE}
#!/usr/bin/env bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#

# Example of setting a namespace context:
kubectl config set-context dev --namespace=default --cluster=gke_frstack-1077_us-central1-f_openam \
--user=gke_frstack-1077_us-central1-f_openam


kubectl config set-context tenant1 --namespace=tenant1 --cluster=gke_frstack-1077_us-central1-f_openam \
      --user=gke_frstack-1077_us-central1-f_openam


# To switch names spaces:

kubectl config use-context dev

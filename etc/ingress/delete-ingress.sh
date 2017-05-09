#!/bin/bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Tear down the ingress.

kubectl delete -f ingress-gke.yaml
kubectl delete -f default-backend.yaml
kubectl delete -f static-ip-svc.yaml
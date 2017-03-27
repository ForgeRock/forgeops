#!/bin/bash
# Copyright (c) 2016-2017 ForgeRock AS. Use of this source code is subject to the
# Common Development and Distribution License (CDDL) that can be found in the LICENSE file
#
# Tear down the ingress.

kubectl delete -f ingress.yaml
kubectl delete rc default-http-backend
kubectl delete svc default-http-backend
kubectl delete configmap tcp-configmap
kubectl delete configmap nginx-load-balancer-conf


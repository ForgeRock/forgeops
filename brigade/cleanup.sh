#!/usr/bin/env bash

kubectl delete -l heritage=brigade pvc,pod,secret

#!/usr/bin/env bash

pulumi stack output kubeconfig > kubeconfig
export KUBECONFIG=$PWD/kubeconfig
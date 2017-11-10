#!/usr/bin/env bash
# Enable all the bells and whistles for using RBAC and istio.
# TODO: Not clear if the initializer stuff is still needed for 1.8

minikube start \
--extra-config=apiserver.Admission.PluginNames="Initializers,NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,GenericAdmissionWebhook,ResourceQuota,PodPreset"

# --extra-config=apiserver.Authorization.Mode=RBAC \

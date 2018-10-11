#!/usr/bin/env bash
# Create ArgoCD app instances
# This should be a one time activity - once deployed the app is syncronized, not deleted


# Sample - this sets the helm values path
# Helm values are relative to the helm chart, not the root
#argocd app set ds-userstore --values ../../cicd/argo/userstore.yaml

#REPO=https://github.com/wstrange/forgeops
REPO=https://github.com/ForgeRock/forgeops
REVISION=master
NAMESPACE=test

# Deploy ds instances

for app in configstore userstore; do
    argocd app create --name ds-$app \
        --repo  $REPO \
        --revision $REVISION \
        --dest-namespace $NAMESPACE \
        --dest-server https://kubernetes.default.svc \
        --path helm/ds \
        --values ../../cicd/argo/$app.yaml

        argocd app sync ds-$app
done

for app in frconfig openam amster; do
    argocd app create --name test-$app \
        --repo $REPO \
        --revision $REVISION \
        --dest-namespace $NAMESPACE \
        --dest-server https://kubernetes.default.svc \
        --path helm/$app \
        --values ../../cicd/argo/$app.yaml

    argocd app sync test-$app

done



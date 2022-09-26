# deploy.tf - deploy components into cluster

resource "azurerm_role_assignment" "network_contributor" {
  scope = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
  role_definition_name = "Network Contributor"
  principal_id = module.aks.cluster_identity.principal_id
  #skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "virtual_machine_contributor" {
  scope = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
  role_definition_name = "Virtual Machine Contributor"
  principal_id = module.aks.cluster_identity.principal_id
  #skip_service_principal_aad_check = true
}

#resource "azurerm_role_assignment" "key_vault_administrator" {
#  scope = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
#  role_definition_name = "Key Vault Administrator"
#  principal_id = module.aks.kubelet_identity[0].object_id
#  #skip_service_principal_aad_check = true
#}

resource "azurerm_role_assignment" "dns_zone_contributor" {
  scope = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
  role_definition_name = "DNS Zone Contributor"
  principal_id = module.aks.kubelet_identity[0].object_id
  #skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "private_dns_zone_contributor" {
  scope = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
  role_definition_name = "Private DNS Zone Contributor"
  principal_id = module.aks.kubelet_identity[0].object_id
  #skip_service_principal_aad_check = true
}

#resource "azurerm_role_assignment" "managed_identity_operator" {
#  scope = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
#  role_definition_name = "Managed Identity Operator"
#  principal_id = module.aks.kubelet_identity[0].object_id
#  #skip_service_principal_aad_check = true
#}

#resource "azuread_application" "external_secrets" {
#  display_name = local.cluster_name
#  owners       = [module.aks.kubelet_identity[0].object_id]
#}

#resource "azuread_application_federated_identity_credential" "external_secrets" {
#  application_object_id = azuread_application.external_secrets.object_id
#  display_name          = local.cluster_name
#  audiences             = ["api://AzureADTokenExchange"]
#  issuer                = module.aks.oidc_issuer_url
#  subject               = "system:serviceaccount:external-secrets:external-secrets"
#}

resource "azurerm_key_vault" "current" {
  name                        = local.cluster_name
  resource_group_name         = azurerm_resource_group.main.name
  location                    = azurerm_resource_group.main.location
  enabled_for_disk_encryption = true
  tenant_id                   = module.aks.cluster_identity.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = module.aks.cluster_identity.tenant_id
    object_id = module.aks.kubelet_identity[0].object_id

    key_permissions = [
      "Get",
    ]

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover",
      "Purge"
    ]

    storage_permissions = [
      "Get",
    ]
  }
}

locals {
  values_workload_identity_webhook = <<-EOF
  # Values from terraform AKS module
  azureTenantID: "${module.aks.cluster_identity.tenant_id}"
  EOF
}

resource "helm_release" "workload_identity_webhook" {
  count = 0

  name                  = "workload-identity-webhook"
  repository            = "https://azure.github.io/azure-workload-identity/charts"
  chart                 = "workload-identity-webhook"
  version               = "v0.13.0"
  namespace             = "workload-identity-webook"
  create_namespace      = true
  reuse_values          = false
  reset_values          = true
  max_history           = 12
  render_subchart_notes = false
  timeout               = 600

  values = [local.values_workload_identity_webhook]

  #depends_on = [module.aks]
}

locals {
  values_aad_pod_identity = <<-EOF
  # Values from terraform AKS module
  nmi:
    allowNetworkPluginKubenet: true
  rbac:
    allowAccessToSecrets: true
    createUserFacingClusterRoles: true
  EOF
}

resource "helm_release" "aad_pod_identity" {
  count = 0

  name                  = "aad-pod-identity"
  repository            = "https://raw.githubusercontent.com/Azure/aad-pod-identity/master/charts"
  chart                 = "aad-pod-identity"
  version               = "4.1.13"
  namespace             = "aad-pod-identity"
  create_namespace      = true
  reuse_values          = false
  reset_values          = true
  max_history           = 12
  render_subchart_notes = false
  timeout               = 600

  values = [local.values_aad_pod_identity]

  #depends_on = [module.aks]
}

module "helm" {
  source = "../helm"

  chart_configs = var.cluster.helm

  charts = {
    "external-secrets" = {
      "values" = <<-EOF
      # Values from terraform AKS module
      #serviceAccount:
      #  annotations:
      #    azure.workload.identity/client-id: "${module.aks.kubelet_identity[0].client_id}"
      #    azure.workload.identity/tenant-id: "${module.aks.cluster_identity.tenant_id}"
      #  extraLabels:
      #    #azure.workload.identity/use: "true"
      #    aadpodidentity:
      EOF
    },
    "external-dns" = {
      "values" = <<-EOF
      # Values from terraform AKS module
      provider: azure

      azure:
        resourceGroup: "${local.cluster_name}"
        tenantId: "${module.aks.cluster_identity.tenant_id}"
        subscriptionId: "${data.azurerm_subscription.current.subscription_id}"
        useManagedIdentityExtension: true
        userAssignedIdentityID: "${module.aks.kubelet_identity[0].client_id}"

      txtOwnerId: "${local.cluster_name}.${var.cluster.location.region}"
      EOF
    },
    "ingress-nginx" = {
      "values" = <<-EOF
      # Values from terraform AKS module
      controller:
        service:
          loadBalancerIP: ${azurerm_public_ip.ingress.ip_address}
          annotations:
            service.beta.kubernetes.io/azure-load-balancer-resource-group: ${azurerm_resource_group.main.name}
      EOF
    },
    "haproxy-ingress" = {
      "values" = <<-EOF
      # Values from terraform AKS module
      controller:
        service:
          loadBalancerIP: ${azurerm_public_ip.ingress.ip_address}
          annotations:
            service.beta.kubernetes.io/azure-load-balancer-resource-group: ${azurerm_resource_group.main.name}
        #tolerations:
        #  - key: "WorkerAttachedToExtLoadBalancer"
        #    operator: "Exists"
        #    effect: "NoSchedule"
      EOF
    },
    "cert-manager" = {
      "values" = <<-EOF
      # Values from terraform AKS module
      EOF
    },
    "kube-prometheus-stack" = {
      "values" = <<-EOF
      # Values from terraform AKS module
      EOF
    },
    "elasticsearch" = {
      "values" = <<-EOF
      # Values from terraform AKS module
      EOF
    },
    "logstash" = {
      "values" = <<-EOF
      # Values from terraform AKS module
      EOF
    },
    "kibana" = {
      "values" = <<-EOF
      # Values from terraform AKS module
      EOF
    },
    "raw-k8s-resources" = {
      "values" = <<-EOF
      # Values from terraform AKS module
      resources:
        - apiVersion: external-secrets.io/v1beta1
          kind: ClusterSecretStore
          metadata:
            name: default-secrets-store
          spec:
            provider:
              azurekv:
                environmentType: PublicCloud
                #authType: WorkloadIdentity
                authType: ManagedIdentity
                vaultUrl: ${azurerm_key_vault.current.vault_uri}
                serviceAccountRef:
                  name: external-secrets
                  namespace: external-secrets
        - apiVersion: storage.k8s.io/v1
          kind: StorageClass
          metadata:
            name: fast
            #annotations:
            #  "storageclass.kubernetes.io/is-default-class": "true"
          parameters:
            storageaccounttype: Premium_LRS
            kind: Managed
          provisioner: disk.csi.azure.com
          reclaimPolicy: Delete
          volumeBindingMode: WaitForFirstConsumer
        - apiVersion: storage.k8s.io/v1
          kind: StorageClass
          metadata:
            name: standard
          parameters:
            storageaccounttype: Standard_LRS
            kind: Managed
          provisioner: kubernetes.io/azure-disk
          reclaimPolicy: Delete
          volumeBindingMode: WaitForFirstConsumer
        - apiVersion: snapshot.storage.k8s.io/v1
          kind: VolumeSnapshotClass
          metadata:
            name: ds-snapshot-class
          driver: disk.csi.azure.com
          deletionPolicy: Delete
      EOF
    }
  }

  #depends_on = [module.aks, azurerm_public_ip.ingress, helm_release.workload_identity_webhook, azuread_application_federated_identity_credential.external_secrets]
  #depends_on = [module.aks, azurerm_public_ip.ingress, helm_release.workload_identity_webhook]
  depends_on = [module.aks, azurerm_public_ip.ingress, helm_release.aad_pod_identity]
}


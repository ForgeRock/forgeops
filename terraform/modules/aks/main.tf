# main.tf - cluster module

module "common" {
  source = "../common"

  forgerock = var.forgerock
}

data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

resource "random_id" "cluster" {
  byte_length = 2
}

locals {
  cluster_name = replace(var.cluster.meta.cluster_name, "<id>", random_id.cluster.hex)
}

resource "random_id" "prefix" {
  byte_length = 8
}

resource "azurerm_resource_group" "main" {
  name = local.cluster_name
  location = var.cluster.location.region

  tags = {
    cluster_name = local.cluster_name
  }
}

# az feature register --name EnableOIDCIssuerPreview --namespace Microsoft.ContainerService
# az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/EnableOIDCIssuerPreview')].{Name:name,State:properties.state}"
#
#resource "azurerm_resource_provider_registration" "main" {
#  name = "Microsoft.ContainerService"
#
#  feature {
#    name       = "EnableOIDCIssuerPreview"
#    registered = true
#  }
#}

resource "azurerm_public_ip" "ingress" {
  name = local.cluster_name
  resource_group_name = azurerm_resource_group.main.name
  location = azurerm_resource_group.main.location

  allocation_method = "Static"
  sku = "Standard"

  tags = {
    cluster_name = local.cluster_name
  }
}

data "azurerm_kubernetes_service_versions" "kubernetes_version" {
    location = azurerm_resource_group.main.location
    version_prefix = var.cluster.meta.kubernetes_version
    include_preview = false

    depends_on = [azurerm_resource_group.main]
}

module "aks" {
  source                     = "Azure/aks/azurerm"
  version                    = "~> 6.0"

  cluster_name                            = local.cluster_name
  location                                = azurerm_resource_group.main.location
  resource_group_name                     = azurerm_resource_group.main.name
  prefix                                  = local.cluster_name
  kubernetes_version                      = data.azurerm_kubernetes_service_versions.kubernetes_version.latest_version

  agents_pool_name                        = "default"
  agents_availability_zones               = var.cluster.location.zones
  agents_size                             = var.cluster.node_pool.type
  os_disk_size_gb                         = 100
  agents_count                            = var.cluster.node_pool.initial_count
  agents_min_count                        = var.cluster.node_pool.min_count
  agents_max_count                        = var.cluster.node_pool.max_count
  #agents_max_pods                         = 100
  agents_type                             = "VirtualMachineScaleSets"
  agents_labels                           = module.common.asset_labels
  agents_tags                             = module.common.asset_labels
  enable_auto_scaling                     = true
  #enable_host_encryption                  = true

  identity_type                           = "SystemAssigned"

  #network_plugin                          = "azure"
  #network_policy                          = "azure"
  network_plugin                          = "kubenet"

  oidc_issuer_enabled                      = true

  #http_application_routing_enabled        = true
  #ingress_application_gateway_enabled     = true
  #ingress_application_gateway_name        = "${random_id.prefix.hex}-agw"
  #ingress_application_gateway_subnet_cidr = "10.52.1.0/24"

  #azure_policy_enabled                    = true
  #client_id                               = var.client_id
  #client_secret                           = var.client_secret
  #disk_encryption_set_id                  = azurerm_disk_encryption_set.des.id

  #local_account_disabled                  = true
  log_analytics_workspace_enabled         = true

  #private_cluster_enabled                 = true
  #rbac_aad_managed                        = true
  #role_based_access_control_enabled       = true

  sku_tier                                = "Paid"
  #vnet_subnet_id                          = azurerm_subnet.test.id

  depends_on = [azurerm_resource_group.main]
}


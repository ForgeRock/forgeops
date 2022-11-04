# outputs.tf - cluster module outputs

locals {
  kube_config = {
    "config_path"            = "~/.kube/config-tf.aks.${module.aks.location}.${module.aks.aks_name}"
    "host" = module.aks.host,
    "cluster_ca_certificate" = module.aks.cluster_ca_certificate,
    "client_certificate"     = module.aks.client_certificate,
    "client_key"             = module.aks.client_key,
    "token"                  = null
  }
}

output "kube_config" {
  value = local.kube_config
}

resource "local_file" "kube_config" {
  filename             = pathexpand(local.kube_config["config_path"])
  file_permission      = "0600"
  directory_permission = "0775"
  content              = module.aks.kube_config_raw
}

module "common-output" {
  source = "../common-output"

  cluster       = merge(var.cluster, {type = "AKS", meta = {cluster_name = local.cluster_name}})
  kube_config   = local.kube_config
  helm_metadata = module.helm.metadata

  depends_on = [module.helm]
}

output "cluster_info" {
  value = module.common-output.cluster_info
}


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

output "cluster_info" {
  value = <<-EOF
  =============================================================================

      EKS cluster name: ${local.cluster_name}
  EKS cluster location: ${var.cluster.location.region}

  Execute the following to begin working with the new cluster:

  export KUBECONFIG=${local.kube_config["config_path"]}

  =============================================================================
  EOF

    depends_on = [module.helm]
}


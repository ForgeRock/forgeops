# outputs.tf - cluster module outputs

locals {
  kube_config = {
    "config_path" = "~/.kube/config-tf.gke.${module.gke.region}.${module.gke.name}"
    "host" = "https://${module.gke.endpoint}",
    "cluster_ca_certificate" = module.gke.ca_certificate,
    "client_certificate" = "",
    "client_key" = "",
    "token" = data.google_client_config.default.access_token
  }
}

output "kube_config" {
  value = local.kube_config
}

resource "local_file" "kube_config" {
  filename = pathexpand(local.kube_config["config_path"])
  file_permission = "0600"
  directory_permission = "0775"
  content  = <<-EOF
  apiVersion: v1
  kind: Config
  preferences:
    colors: true
  current-context: ${module.gke.name}
  contexts:
  - context:
      cluster: ${module.gke.name}
      namespace: default
      user: ${module.gke.name}
    name: ${module.gke.name}
  clusters:
  - cluster:
      server: ${local.kube_config["host"]}
      certificate-authority-data: ${local.kube_config["cluster_ca_certificate"]}
    name: ${module.gke.name}
  users:
  - name: ${module.gke.name}
    user:
      auth-provider:
        config:
          cmd-args: config config-helper --format=json
          cmd-path: gcloud
          expiry-key: '{.credential.token_expiry}'
          token-key: '{.credential.access_token}'
        name: gcp
  EOF
}

output "cluster_info" {
  value = <<-EOF
  =============================================================================

      GKE cluster name: ${local.cluster_name}
  GKE cluster location: ${var.cluster.location.region}

  Execute the following to begin working with the new cluster:

  export KUBECONFIG=${local.kube_config["config_path"]}

  =============================================================================
  EOF

    depends_on = [module.helm]
}


# outputs.tf - cluster module outputs

locals {
  kube_config = {
    "config_path"            = "~/.kube/config-tf.eks.${var.cluster.location.region}.${local.cluster_name}"
    "host"                   = module.eks.cluster_endpoint,
    "cluster_ca_certificate" = module.eks.cluster_certificate_authority_data,
    "client_certificate"     = "",
    "client_key"             = "",
    "token"                  = data.aws_eks_cluster_auth.cluster.token
  }
  kube_config_yaml = yamlencode({
        apiVersion = "v1"
        kind = "Config"
        current-context = module.eks.cluster_id
        contexts = [{
          name = module.eks.cluster_id
          context = {
            cluster = module.eks.cluster_id
            user = module.eks.cluster_id
          }
        }]
        clusters = [{
          name = module.eks.cluster_id
          cluster = {
            certificate-authority-data = local.kube_config["cluster_ca_certificate"]
            server = local.kube_config["host"]
          }
        }]
        users = [{
          name = module.eks.cluster_id
          user = {
            token = local.kube_config["token"]
          }
        }]
    })
}

output "kube_config" {
  value = local.kube_config
}

resource "local_file" "kube_config" {
  filename             = pathexpand(local.kube_config["config_path"])
  file_permission      = "0600"
  directory_permission = "0775"
  content              = <<-EOF
  apiVersion: v1
  kind: Config
  preferences:
    colors: true
  current-context: ${module.eks.cluster_id}
  contexts:
  - context:
      cluster: ${module.eks.cluster_id}
      namespace: default
      user: ${module.eks.cluster_id}
    name: ${module.eks.cluster_id}
  clusters:
  - cluster:
      server: ${local.kube_config["host"]}
      certificate-authority-data: ${local.kube_config["cluster_ca_certificate"]}
    name: ${module.eks.cluster_id}
  users:
  - name: ${module.eks.cluster_id}
    user:
      exec:
        apiVersion: client.authentication.k8s.io/v1beta1
        command: aws
        args:
        - eks
        - get-token
        - --cluster-name
        - ${module.eks.cluster_id}
        env: null
  EOF
}

module "common-output" {
  source = "../common-output"

  cluster       = merge(var.cluster, {type = "EKS", meta = {cluster_name = local.cluster_name}})
  kube_config   = local.kube_config
  helm_metadata = module.helm.metadata

  depends_on = [module.helm]
}

output "cluster_info" {
  value = module.common-output.cluster_info
}


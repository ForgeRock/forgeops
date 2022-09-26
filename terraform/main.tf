# main.tf - root module

resource "local_file" "clusters" {
  filename             = "${path.module}/clusters.tf"
  file_permission      = "0664"
  directory_permission = "0775"

  content = <<-EOF
  ### GKE ####
  %{ for key in keys(local.clusters.gke) }
  provider "google" {
    alias       = "${key}"

    region      = local.clusters.gke["${key}"].location["region"]
    project     = local.clusters.gke["${key}"].auth["project_id"]
    credentials = local.clusters.gke["${key}"].auth["credentials"]
  }

  provider "kubernetes" {
    alias                  = "${key}"

    host                   = module.${key}.kube_config["host"]
    cluster_ca_certificate = base64decode(module.${key}.kube_config["cluster_ca_certificate"])
    client_certificate     = base64decode(module.${key}.kube_config["client_certificate"])
    client_key             = module.${key}.kube_config["client_key"]
    token                  = module.${key}.kube_config["token"]
    experiments {
      manifest_resource = true
    }
  }

  provider "helm" {
    alias = "${key}"

    kubernetes {
      host                   = module.${key}.kube_config["host"]
      cluster_ca_certificate = base64decode(module.${key}.kube_config["cluster_ca_certificate"])
      client_certificate     = base64decode(module.${key}.kube_config["client_certificate"])
      client_key             = module.${key}.kube_config["client_key"]
      token                  = module.${key}.kube_config["token"]
    }
  }

  module "${key}" {
    source    = "./modules/gke"

    cluster   = local.clusters.gke["${key}"]
    forgerock = var.forgerock

    providers = {
      google     = google.${key}
      kubernetes = kubernetes.${key}
      helm       = helm.${key}
    }
    depends_on = [local_file.clusters]
  }

  output "${key}" {
    value = format("\n\nGKE Cluster Configuration: %s\n%s\n", "${key}", module.${key}.cluster_info)
  }
  %{ endfor }

  ### EKS ####
  %{ for key in keys(local.clusters.eks) }
  provider "aws" {
    alias      = "${key}"

    region     = local.clusters.eks["${key}"].location["region"]
    access_key = local.clusters.eks["${key}"].auth["access_key"]
    secret_key = local.clusters.eks["${key}"].auth["secret_key"]
  }

  provider "kubernetes" {
    alias                  = "${key}"

    host                   = module.${key}.kube_config["host"]
    cluster_ca_certificate = base64decode(module.${key}.kube_config["cluster_ca_certificate"])
    client_certificate     = base64decode(module.${key}.kube_config["client_certificate"])
    client_key             = module.${key}.kube_config["client_key"]
    token                  = module.${key}.kube_config["token"]
    experiments {
      manifest_resource = true
    }
  }

  provider "helm" {
    alias = "${key}"

    kubernetes {
      host                   = module.${key}.kube_config["host"]
      cluster_ca_certificate = base64decode(module.${key}.kube_config["cluster_ca_certificate"])
      client_certificate     = base64decode(module.${key}.kube_config["client_certificate"])
      client_key             = module.${key}.kube_config["client_key"]
      token                  = module.${key}.kube_config["token"]
    }
  }

  module "${key}" {
    source    = "./modules/eks"

    cluster   = local.clusters.eks["${key}"]
    forgerock = var.forgerock

    providers = {
      aws        = aws.${key}
      kubernetes = kubernetes.${key}
      helm       = helm.${key}
    }
    depends_on = [local_file.clusters]
  }

  output "${key}" {
    value = format("\n\nEKS Cluster Configuration: %s\n%s\n", "${key}", module.${key}.cluster_info)
  }
  %{ endfor }

  ### AKS ####
  %{ for key in keys(local.clusters.aks) }
  provider "azurerm" {
    alias = "${key}"

    features {}

    #skip_provider_registration = true
  }

  provider "kubernetes" {
    alias                  = "${key}"

    host                   = module.${key}.kube_config["host"]
    cluster_ca_certificate = base64decode(module.${key}.kube_config["cluster_ca_certificate"])
    client_certificate     = base64decode(module.${key}.kube_config["client_certificate"])
    client_key             = base64decode(module.${key}.kube_config["client_key"])
    token                  = module.${key}.kube_config["token"]
    experiments {
      manifest_resource = true
    }
  }

  provider "helm" {
    alias = "${key}"

    kubernetes {
      host                   = module.${key}.kube_config["host"]
      cluster_ca_certificate = base64decode(module.${key}.kube_config["cluster_ca_certificate"])
      client_certificate     = base64decode(module.${key}.kube_config["client_certificate"])
      client_key             = base64decode(module.${key}.kube_config["client_key"])
      token                  = module.${key}.kube_config["token"]
    }
  }

  module "${key}" {
    source    = "./modules/aks"

    cluster   = local.clusters.aks["${key}"]
    forgerock = var.forgerock

    providers = {
      azurerm    = azurerm.${key}
      kubernetes = kubernetes.${key}
      helm       = helm.${key}
    }
    depends_on = [local_file.clusters]
  }

  output "${key}" {
    value = format("\n\nAKS Cluster Configuration: %s\n%s\n", "${key}", module.${key}.cluster_info)
  }
  %{ endfor }
  EOF
}


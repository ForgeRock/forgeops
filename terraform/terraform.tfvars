# terraform.tfvars - Terraform configuration variables
#
# Copy terraform.tfvars to override.auto.tfvars, then edit override.auto.tfvars
# to customize settings.

forgerock = {
  employee        = false

  billing_entity  = null

  es_useremail    = null
  es_businessunit = null
  es_ownedby      = null
  es_managedby    = null
  es_zone         = null
}

clusters = {
  tf_cluster_gke_small = {
    enabled = false
    type    = "gke"
    auth = {
      project_id  = null
      credentials = null
    }

    meta = {
      cluster_name       = "tf-idp-<id>"
      kubernetes_version = "1.22"
    }

    location = {
      region = "us-east1"
      zones  = ["us-east1-b", "us-east1-c", "us-east1-d"]
    }

    node_pool = {
      type          = "n2-standard-8"
      initial_count = 2
      min_count     = 1
      max_count     = 6
    }

    helm = {
      external-dns = {
        deploy  = true
        #values  = <<-EOF
        # Values from tfvars configuration
        #google:
        #  project: <alt_google_cloud_dns_project>
        #EOF
      },
      cert-manager = {
        deploy  = true
      },
      ingress-nginx = {
        deploy  = true
      },
      haproxy-ingress = {
        deploy  = false
      },
      kube-prometheus-stack = {
        deploy  = false
      },
      elasticsearch = {
        deploy  = false
      },
      logstash = {
        deploy  = false
      },
      kibana = {
        deploy  = false
      }
    }
  },
  tf_cluster_eks_small = {
    enabled = false
    type    = "eks"
    auth = {
      access_key = null
      secret_key = null
    }

    meta = {
      cluster_name       = "tf-idp-<id>"
      kubernetes_version = "1.22"
    }

    location = {
      region = "us-east-1"
      zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
    }

    node_pool = {
      type          = "m5.xlarge"
      initial_count = 2
      min_count     = 1
      max_count     = 6
    }

    helm = {
      external-dns = {
        deploy  = true
        values  = <<-EOF
        # Values from tfvars configuration
        EOF
      },
      cert-manager = {
        deploy  = true
      },
      ingress-nginx = {
        deploy  = true
      },
      haproxy-ingress = {
        deploy  = false
      },
      kube-prometheus-stack = {
        deploy  = false
      },
      elasticsearch = {
        deploy  = false
      },
      logstash = {
        deploy  = false
      },
      kibana = {
        deploy  = false
      }
    }
  },
  tf_cluster_aks_small = {
    enabled = false
    type    = "aks"
    auth = {  # Authenticate with 'az login'
    }

    meta = {
      cluster_name       = "tf-idp-<id>"
      kubernetes_version = "1.22"
    }

    location = {
      region = "eastus"
      zones  = ["1", "2", "3"]
    }

    node_pool = {
      type          = "Standard_DS4_v2"
      initial_count = 2
      min_count     = 1
      max_count     = 6
    }

    helm = {
      external-dns = {
        deploy  = true
        values  = <<-EOF
        # Values from tfvars configuration
        #azure:
        #  resourceGroup: <azure-resource-group-for-dns>
        EOF
      },
      cert-manager = {
        deploy  = true
      },
      ingress-nginx = {
        deploy  = true
      },
      haproxy-ingress = {
        deploy  = false
      },
      kube-prometheus-stack = {
        deploy  = false
      },
      elasticsearch = {
        deploy  = false
      },
      logstash = {
        deploy  = false
      },
      kibana = {
        deploy  = false
      }
    }
  },
}


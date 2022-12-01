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
      initial_count = 3
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
      },
      secret-agent = {
        deploy     = true
      },
      ds-operator = {
        deploy     = true
      },
      identity-platform = {
        deploy     = true
        version    = "7.3"
        values     = <<-EOF
        # Values from tfvars configuration
        #platform:
        #  ingress:
        #    hosts:
        #      - identity-platform.domain.local

        am:
          replicaCount: 2
          resources:
            requests:
              cpu: 2000m
              memory: 4Gi
            limits:
              memory: 4Gi

        idm:
          replicaCount: 2
          resources:
            requests:
              cpu: 1500m
              memory: 2Gi
            limits:
              memory: 2Gi

        ds_idrepo:
          replicaCount: 3
          resources:
            requests:
              memory: 4Gi
              cpu: 1500m
            limits:
              memory: 6Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 100Gi

        ds_cts:
          replicaCount: 3
          resources:
            requests:
              memory: 3Gi
              cpu: 2000m
            limits:
              memory: 5Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 100Gi
        EOF
      }
    }
  },
  tf_cluster_gke_medium = {
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
      type          = "c2-standard-30"
      initial_count = 3
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
      },
      secret-agent = {
        deploy     = true
      },
      ds-operator = {
        deploy     = true
      },
      identity-platform = {
        deploy     = true
        version    = "7.3"
        values     = <<-EOF
        # Values from tfvars configuration
        #platform:
        #  ingress:
        #    hosts:
        #      - identity-platform.domain.local

        am:
          replicaCount: 3
          resources:
            requests:
              cpu: 11000m
              memory: 10Gi
            limits:
              memory: 10Gi

        idm:
          replicaCount: 2
          resources:
            requests:
              cpu: 8000m
              memory: 6Gi
            limits:
              memory: 6Gi

        ds_idrepo:
          replicaCount: 3
          resources:
            requests:
              memory: 11Gi
              cpu: 8000m
            limits:
              memory: 14Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 1000Gi

        ds_cts:
          replicaCount: 3
          resources:
            requests:
              memory: 11Gi
              cpu: 8000m
            limits:
              memory: 14Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 500Gi
        EOF
      }
    }
  },
  tf_cluster_gke_large = {
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
      type          = "c2-standard-16"
      initial_count = 3
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
      },
      secret-agent = {
        deploy     = true
      },
      ds-operator = {
        deploy     = true
      },
      identity-platform = {
        deploy     = true
        version    = "7.3"
        values     = <<-EOF
        # Values from tfvars configuration
        #platform:
        #  ingress:
        #    hosts:
        #      - identity-platform.domain.local

        am:
          replicaCount: 3
          resources:
            requests:
              cpu: 11000m
              memory: 20Gi
            limits:
              memory: 26Gi

        idm:
          replicaCount: 2
          resources:
            requests:
              cpu: 8000m
              memory: 4Gi
            limits:
              memory: 8Gi

        ds_idrepo:
          replicaCount: 3
          resources:
            requests:
              memory: 21Gi
              cpu: 8000m
            limits:
              memory: 29Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 512Gi

        ds_cts:
          replicaCount: 3
          resources:
            requests:
              memory: 11Gi
              cpu: 8000m
            limits:
              memory: 14Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 500Gi
        EOF
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
      initial_count = 3
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
      },
      secret-agent = {
        deploy     = true
      },
      ds-operator = {
        deploy     = true
      },
      identity-platform = {
        deploy     = true
        version    = "7.3"
        values     = <<-EOF
        # Values from tfvars configuration
        #platform:
        #  ingress:
        #    hosts:
        #      - identity-platform.domain.local

        am:
          replicaCount: 2
          resources:
            requests:
              cpu: 2000m
              memory: 4Gi
            limits:
              memory: 4Gi

        idm:
          replicaCount: 2
          resources:
            requests:
              cpu: 1500m
              memory: 2Gi
            limits:
              memory: 2Gi

        ds_idrepo:
          replicaCount: 3
          resources:
            requests:
              memory: 4Gi
              cpu: 1500m
            limits:
              memory: 6Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 100Gi

        ds_cts:
          replicaCount: 3
          resources:
            requests:
              memory: 3Gi
              cpu: 2000m
            limits:
              memory: 5Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 100Gi
        EOF
      }
    }
  },
  tf_cluster_eks_medium = {
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
      type          = "c5.9xlarge"
      initial_count = 3
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
      },
      secret-agent = {
        deploy     = true
      },
      ds-operator = {
        deploy     = true
      },
      identity-platform = {
        deploy     = true
        version    = "7.3"
        values     = <<-EOF
        # Values from tfvars configuration
        #platform:
        #  ingress:
        #    hosts:
        #      - identity-platform.domain.local

        am:
          replicaCount: 3
          resources:
            requests:
              cpu: 11000m
              memory: 10Gi
            limits:
              memory: 10Gi

        idm:
          replicaCount: 2
          resources:
            requests:
              cpu: 8000m
              memory: 6Gi
            limits:
              memory: 6Gi

        ds_idrepo:
          replicaCount: 3
          resources:
            requests:
              memory: 11Gi
              cpu: 8000m
            limits:
              memory: 14Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 1000Gi

        ds_cts:
          replicaCount: 3
          resources:
            requests:
              memory: 11Gi
              cpu: 8000m
            limits:
              memory: 14Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 500Gi
        EOF
      }
    }
  },
  tf_cluster_eks_large = {
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
      type          = "m5.8xlarge"
      initial_count = 3
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
      },
      secret-agent = {
        deploy     = true
      },
      ds-operator = {
        deploy     = true
      },
      identity-platform = {
        deploy     = true
        version    = "7.3"
        values     = <<-EOF
        # Values from tfvars configuration
        #platform:
        #  ingress:
        #    hosts:
        #      - identity-platform.domain.local

        am:
          replicaCount: 3
          resources:
            requests:
              cpu: 11000m
              memory: 20Gi
            limits:
              memory: 26Gi

        idm:
          replicaCount: 2
          resources:
            requests:
              cpu: 8000m
              memory: 4Gi
            limits:
              memory: 8Gi

        ds_idrepo:
          replicaCount: 3
          resources:
            requests:
              memory: 21Gi
              cpu: 8000m
            limits:
              memory: 29Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 512Gi

        ds_cts:
          replicaCount: 3
          resources:
            requests:
              memory: 11Gi
              cpu: 8000m
            limits:
              memory: 14Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 500Gi
        EOF
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
      initial_count = 3
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
      },
      secret-agent = {
        deploy     = true
      },
      ds-operator = {
        deploy     = true
      },
      identity-platform = {
        deploy     = true
        version    = "7.3"
        values     = <<-EOF
        # Values from tfvars configuration
        #platform:
        #  ingress:
        #    hosts:
        #      - identity-platform.domain.local

        am:
          replicaCount: 2
          resources:
            requests:
              cpu: 2000m
              memory: 4Gi
            limits:
              memory: 4Gi

        idm:
          replicaCount: 2
          resources:
            requests:
              cpu: 1500m
              memory: 2Gi
            limits:
              memory: 2Gi

        ds_idrepo:
          replicaCount: 3
          resources:
            requests:
              memory: 4Gi
              cpu: 1500m
            limits:
              memory: 6Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 100Gi

        ds_cts:
          replicaCount: 3
          resources:
            requests:
              memory: 3Gi
              cpu: 2000m
            limits:
              memory: 5Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 100Gi
        EOF
      }
    }
  },
  tf_cluster_aks_medium = {
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
      type          = "Standard_F32s_v2"
      initial_count = 3
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
      },
      secret-agent = {
        deploy     = true
      },
      ds-operator = {
        deploy     = true
      },
      identity-platform = {
        deploy     = true
        version    = "7.3"
        values     = <<-EOF
        # Values from tfvars configuration
        #platform:
        #  ingress:
        #    hosts:
        #      - identity-platform.domain.local

        am:
          replicaCount: 3
          resources:
            requests:
              cpu: 11000m
              memory: 10Gi
            limits:
              memory: 10Gi

        idm:
          replicaCount: 2
          resources:
            requests:
              cpu: 8000m
              memory: 6Gi
            limits:
              memory: 6Gi

        ds_idrepo:
          replicaCount: 3
          resources:
            requests:
              memory: 11Gi
              cpu: 8000m
            limits:
              memory: 14Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 1000Gi

        ds_cts:
          replicaCount: 3
          resources:
            requests:
              memory: 11Gi
              cpu: 8000m
            limits:
              memory: 14Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 500Gi
        EOF
      }
    }
  },
  tf_cluster_aks_large = {
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
      type          = "Standard_F16s_v2"
      initial_count = 3
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
      },
      secret-agent = {
        deploy     = true
      },
      ds-operator = {
        deploy     = true
      },
      identity-platform = {
        deploy     = true
        version    = "7.3"
        values     = <<-EOF
        # Values from tfvars configuration
        #platform:
        #  ingress:
        #    hosts:
        #      - identity-platform.domain.local

        am:
          replicaCount: 3
          resources:
            requests:
              cpu: 11000m
              memory: 20Gi
            limits:
              memory: 26Gi

        idm:
          replicaCount: 2
          resources:
            requests:
              cpu: 8000m
              memory: 4Gi
            limits:
              memory: 8Gi

        ds_idrepo:
          replicaCount: 3
          resources:
            requests:
              memory: 21Gi
              cpu: 8000m
            limits:
              memory: 29Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 512Gi

        ds_cts:
          replicaCount: 3
          resources:
            requests:
              memory: 11Gi
              cpu: 8000m
            limits:
              memory: 14Gi
          volumeClaimSpec:
            storageClassName: fast
            resources:
              requests:
                storage: 500Gi
        EOF
      }
    }
  },
}


# main.tf - cluster module

module "common" {
  source = "../common"

  forgerock = var.forgerock
}

resource "random_id" "cluster" {
  byte_length = 2
}

locals {
  cluster_name = replace(var.cluster.meta.cluster_name, "<id>", random_id.cluster.hex)
}

data "google_project" "cluster" {
}

locals {
  project = trimprefix(data.google_project.cluster.id, "projects/")
}

# google_client_config and kubernetes provider must be explicitly specified like the following.
data "google_client_config" "default" {}

module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google"
  project_id                 = var.cluster.auth.project_id
  name                       = local.cluster_name
  region                     = var.cluster.location.region
  zones                      = var.cluster.location.zones
  #network                    = "vpc-01"
  #subnetwork                 = "${var.cluster.location.region}-01"
  network                    = "default"
  subnetwork                 = "default"
  ip_range_pods              = null
  ip_range_services          = null
  #ip_range_pods              = "${var.cluster.location.region}-01-gke-01-pods"
  #ip_range_services          = "${var.cluster.location.region}-01-gke-01-services"
  http_load_balancing        = false
  network_policy             = false
  horizontal_pod_autoscaling = true
  filestore_csi_driver       = true

  release_channel            = "REGULAR"
  kubernetes_version         = var.cluster.meta.kubernetes_version
  cluster_resource_labels    = module.common.asset_labels

  node_pools = [
    {
      name                      = "default-node-pool"
      machine_type              = var.cluster.node_pool.type
      #node_locations            = "us-central1-b,us-central1-c"
      min_count                 = var.cluster.node_pool.min_count
      max_count                 = var.cluster.node_pool.max_count
      local_ssd_count           = 0
      disk_size_gb              = 100
      disk_type                 = "pd-ssd"
      image_type                = "COS_CONTAINERD"
      enable_gcfs               = true  # AKA image streaming
      auto_repair               = true
      auto_upgrade              = true
      #service_account           = "project-service-account@<PROJECT ID>.iam.gserviceaccount.com"
      preemptible               = false
      initial_node_count        = var.cluster.node_pool.initial_count
    },
  ]

  node_pools_oauth_scopes = {
    all = []

    default-node-pool = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  node_pools_labels = {
    all = {}

    default-node-pool = {
      default-node-pool = true
    }
  }

  node_pools_metadata = {
    all = {}

    default-node-pool = {
      node-pool-metadata-custom-value = "my-node-pool"
    }
  }

  node_pools_taints = {
    all = []

    default-node-pool = [
      {
        key    = "default-node-pool"
        value  = true
        effect = "PREFER_NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []

    default-node-pool = [
      "default-node-pool",
    ]
  }
}


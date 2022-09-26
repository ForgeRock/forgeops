# locals.tf - root module local variable definitions

locals {
  clusters = {
    gke = {
      for key in keys(var.clusters):
        key => var.clusters[key] if lower(var.clusters[key].type) == "gke" && var.clusters[key].enabled == true
    }
    eks = {
      for key in keys(var.clusters):
        key => var.clusters[key] if lower(var.clusters[key].type) == "eks" && var.clusters[key].enabled == true
    }
    aks = {
      for key in keys(var.clusters):
        key => var.clusters[key] if lower(var.clusters[key].type) == "aks" && var.clusters[key].enabled == true
    }
  }
}


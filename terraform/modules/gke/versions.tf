# versions.tf

terraform {
  required_providers {
    google = "~> 4.18"

    kubernetes = "~> 2.10"
    helm       = "~> 2.5"
    random     = "~> 3.1"
    null       = "~> 3.1"
    external   = "~> 2.2"
    local      = "~> 2.2"
  }
}


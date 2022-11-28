# versions.tf

terraform {
  required_providers {
    aws        = "~> 4.41"

    kubernetes = "~> 2.16"
    helm       = "~> 2.7"

    random     = "~> 3.1"
    null       = "~> 3.1"
    external   = "~> 2.2"
    local      = "~> 2.2"
  }
}


# versions.tf

terraform {
  required_providers {
    azurerm = "~> 3.33"

    kubernetes = "~> 2.16"
    helm       = "~> 2.7"

    random     = "~> 3.1"
    null       = "~> 3.1"
    external   = "~> 2.2"
    local      = "~> 2.2"
  }
}


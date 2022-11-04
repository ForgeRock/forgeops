
variable "cluster" {
  description = "Cluster settings"
  type = object({
    type = string
    auth = map(string)
    meta = map(string)

    location = object({
      region = string
      zones = list(string)
    })

    node_pool = object({
      type = string
      initial_count = number
      min_count = number
      max_count = number
    })

    helm = map(
      map(string)
    )
  })

  default = {
    type = null
    auth = null
    meta = null

    location = {
      region = null
      zones = null
    }

    node_pool = {
      type = null
      initial_count = null
      min_count = null
      max_count = null
    }

    helm = {}
  }
}

variable "kube_config" {
  description = "Cluster kubernetes configuration"
  type = map(string)

  default = {}
}

variable "helm_metadata" {
  description = "Cluster helm metadata"
  type = map(
    map(string)
  )

  default = {}
}


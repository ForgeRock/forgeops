variable "forgerock" {
  description = "ForgeRock employee settings"
  type = object({
    employee        = bool
    billing_entity  = string

    es_useremail    = string
    es_businessunit = string
    es_ownedby      = string
    es_managedby    = string
    es_zone         = string
  })

  default = {
    employee        = null
    billing_entity  = null

    es_useremail    = null
    es_businessunit = null
    es_ownedby      = null
    es_managedby    = null
    es_zone         = null
  }
}

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


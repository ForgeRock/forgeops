# variables.tf - variable definitions for the root module

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

  validation {
    condition     = var.forgerock["employee"] != null
    error_message = "Variable forgerock.employee must not be null."
  }

  validation {
    condition     = var.forgerock["employee"] == null || var.forgerock["employee"] == false || (var.forgerock["employee"] == true && var.forgerock["billing_entity"] != null && var.forgerock["es_useremail"] != null && var.forgerock["es_businessunit"] != null && var.forgerock["es_ownedby"] != null && var.forgerock["es_managedby"] != null)
    error_message = "ForgeRock employees must set forgerock.billing_entity, forgerock.es_useremail, forgerock.es_businessunit, forgerock.es_ownedby, and forgerock.es_managedby variables."
  }
}

variable "clusters" {
  description = "Cluster settings"
  type = map(object({
    enabled = bool
    type    = string
    auth    = map(string)
    meta    = map(string)

    location = object({
      region = string
      zones  = list(string)
    })

    node_pool = object({
      type          = string
      initial_count = number
      min_count     = number
      max_count     = number
    })

    helm = map(
      map(string)
    )
  }))

  default = {}
  #default = {
  #  auth = null
  #  meta = null
  #
  #  location = {
  #    region = null
  #    zones  = null
  #  }
  #
  #  node_pool = {
  #    type          = null
  #    initial_count = null
  #    min_count     = null
  #    max_count     = null
  #  }
  #
  #  helm = null
  #}
}


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


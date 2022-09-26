
locals {
  asset_labels = var.forgerock.employee == true ? {
    es_zone         = var.forgerock["es_zone"]
    es_ownedby      = var.forgerock["es_ownedby"]
    es_managedby    = var.forgerock["es_managedby"]
    es_businessunit = var.forgerock["es_businessunit"]
    es_useremail    = var.forgerock["es_useremail"]
    billing_entity  = var.forgerock["billing_entity"]
  } : {}
}


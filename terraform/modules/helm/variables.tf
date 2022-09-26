# variables.tf - module variable definitions

variable "charts" {
  type = map(
    map(string)
  )
  default = {}
}

variable "chart_configs" {
  type = map(
    map(string)
  )
  default = {}
}


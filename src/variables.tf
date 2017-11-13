variable "vpc_cidr" {}
variable "region" {}
variable "availability_zones" {}

variable "component" {}
variable "deployment_identifier" {}
variable "dependencies" {
  default = ""
}

variable "public_subnets_offset" {
  default = 0
}
variable "private_subnets_offset" {
  default = 0
}

variable "private_zone_id" {}

variable "include_lifecycle_events" {
  default = "yes"
}
variable "infrastructure_events_bucket" {
  default = ""
}

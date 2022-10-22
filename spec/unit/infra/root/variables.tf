variable "region" {}
variable "availability_zones" {
  type = list(string)
}
variable "vpc_cidr" {}

variable "component" {}
variable "deployment_identifier" {}

variable "public_subnets_offset" {
  type = number
  default = null
}
variable "private_subnets_offset" {
  type = number
  default = null
}

variable "dependencies" {
  type = list(string)
  default = null
}

variable "private_zone_id" {
  default = null
}

variable "include_route53_zone_association" {
  default = null
}
variable "include_nat_gateways" {
  default = null
}

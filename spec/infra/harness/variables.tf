variable "region" {}
variable "vpc_cidr" {}
variable "availability_zones" {
  type = list(string)
}

variable "public_subnets_offset" {
  type = number
}
variable "private_subnets_offset" {
  type = number
}

variable "component" {}
variable "deployment_identifier" {}
variable "dependencies" {
  type = list(string)
}

variable "include_route53_zone_association" {}
variable "private_zone_vpc_id" {}

variable "include_nat_gateways" {}

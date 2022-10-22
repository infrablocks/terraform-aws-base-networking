variable "region" {}

variable "component" {}
variable "deployment_identifier" {}

variable "availability_zones" {
  type = list(string)
}
variable "vpc_cidr" {}

variable "domain_name" {}

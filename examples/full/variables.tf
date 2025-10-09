variable "region" {}

variable "component" {}
variable "deployment_identifier" {}

variable "availability_zones" {
  type = map(object({
    cidr_public  = optional(string)
    cidr_private = optional(string)
  }))
}
variable "vpc_cidr" {}

variable "domain_name" {}

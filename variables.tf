variable "vpc_cidr" {
  description = "The CIDR to use for the VPC."
}
variable "region" {
  description = "The region into which to deploy the VPC."
}
variable "availability_zones" {
  description = "The availability zones for which to add subnets."
}

variable "component" {
  description = "The component this network will contain."
}
variable "deployment_identifier" {
  description = "An identifier for this instantiation."
}
variable "dependencies" {
  description = "A comma separated list of components depended on my this component."
  default = ""
}

variable "public_subnets_offset" {
  description = "The number of /24s to offset the public subnets in the VPC CIDR."
  default = 0
}
variable "private_subnets_offset" {
  description = "The number of /24s to offset the private subnets in the VPC CIDR."
  default = 0
}

variable "private_zone_id" {
  description = "The ID of the private Route 53 zone."
}

variable "include_nat_gateway" {
  description = "Whether or not to deploy a NAT gateway for outbound Internet connectivity."
  default = "yes"
}

variable "include_lifecycle_events" {
  description = "Whether or not to notify via S3 of a created VPC."
  default = "yes"
}
variable "infrastructure_events_bucket" {
  description = "S3 bucket in which to put VPC creation events. Required when `include_lifecycle_events` is 'yes'."
  default = ""
}

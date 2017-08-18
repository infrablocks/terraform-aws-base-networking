variable "region" {}
variable "vpc_cidr" {}
variable "availability_zones" {}

variable "component" {}
variable "deployment_identifier" {}
variable "dependencies" {}

variable "bastion_ami" {}
variable "bastion_instance_type" {}
variable "bastion_ssh_public_key_path" {}
variable "bastion_ssh_allow_cidrs" {}

variable "domain_name" {}
variable "public_zone_id" {}
variable "private_zone_id" {}

variable "infrastructure_events_bucket" {}

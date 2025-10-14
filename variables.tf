variable "vpc_cidr" {
  type        = string
  description = "The CIDR to use for the VPC."
}
variable "region" {
  type        = string
  description = "The region into which to deploy the VPC."
}
variable "availability_zones" {
  type        = list(string)
  description = "The availability zones for which to add subnets. Mutually exclusive with availability_zone_configurations."
  default     = null
}

variable "availability_zone_configurations" {
  type = list(object({
    zone                = string
    public_subnet_cidr  = string
    private_subnet_cidr = string
  }))
  description = <<-DESC
    Explicit availability zone configurations with CIDR blocks. Mutually exclusive with availability_zones.
    Use this to specify exact CIDR blocks for each subnet, allowing you to add new AZs without
    changing existing subnet CIDR allocations. Example: [{
      zone = "us-east-1a"
      public_subnet_cidr = "10.0.0.0/24"
      private_subnet_cidr = "10.0.10.0/24"
    }]
  DESC
  default     = null
}

variable "component" {
  type        = string
  description = "The component this network will contain."
}
variable "deployment_identifier" {
  type        = string
  description = "An identifier for this instantiation."
}
variable "dependencies" {
  description = "A comma separated list of components depended on my this component."
  type        = list(string)
  default     = []
}

variable "public_subnets_offset" {
  description = "The number of /24s to offset the public subnets in the VPC CIDR."
  type        = number
  default     = 0
}
variable "private_subnets_offset" {
  description = "The number of /24s to offset the private subnets in the VPC CIDR."
  type        = number
  default     = 128
}

variable "include_route53_zone_association" {
  description = "Whether or not to associate the VPC with a zone id (\"yes\" or \"no\")."
  type        = string
  default     = "yes"
}

variable "private_zone_id" {
  description = "The ID of the private Route 53 zone."
  type        = string
  default     = null
}

variable "include_nat_gateways" {
  description = "Whether or not to deploy NAT gateways in each availability zone for outbound Internet connectivity (\"yes\" or \"no\")."
  type        = string
  default     = "yes"
}

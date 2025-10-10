locals {
  # default for cases when `null` value provided, meaning "use default"
  dependencies                     = var.dependencies == null ? [] : var.dependencies
  public_subnets_offset            = var.public_subnets_offset == null ? 0 : var.public_subnets_offset
  private_subnets_offset           = var.private_subnets_offset == null ? 0 : var.private_subnets_offset
  include_route53_zone_association = var.include_route53_zone_association == null ? "yes" : var.include_route53_zone_association
  include_nat_gateways             = var.include_nat_gateways == null ? "yes" : var.include_nat_gateways

  # Validation: ensure only one of availability_zones or availability_zone_configurations is provided
  _validate_az_input = (
    (var.availability_zones == null && var.availability_zone_configurations == null) ||
    (var.availability_zones != null && var.availability_zone_configurations != null)
  ) ? tobool("ERROR: Exactly one of availability_zones or availability_zone_configurations must be specified.") : true

  # Normalize AZ configuration to a consistent format
  # If availability_zone_configurations is provided, use it directly
  # Otherwise, generate configurations from availability_zones list
  az_configurations = var.availability_zone_configurations != null ? var.availability_zone_configurations : [
    for idx, az in var.availability_zones : {
      zone                = az
      public_subnet_cidr  = cidrsubnet(var.vpc_cidr, 8, idx + local.public_subnets_offset)
      private_subnet_cidr = cidrsubnet(var.vpc_cidr, 8, idx + 128 + local.private_subnets_offset)
    }
  ]

  # Create a map keyed by AZ name for easy lookup in resources
  az_map = { for config in local.az_configurations : config.zone => config }

  # List of AZ names for outputs and other references
  availability_zones = [for config in local.az_configurations : config.zone]
}

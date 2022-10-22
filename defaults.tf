locals {
  # default for cases when `null` value provided, meaning "use default"
  dependencies                     = var.dependencies == null ? [] : var.dependencies
  public_subnets_offset            = var.public_subnets_offset == null ? 0 : var.public_subnets_offset
  private_subnets_offset           = var.private_subnets_offset == null ? 0 : var.private_subnets_offset
  include_route53_zone_association = var.include_route53_zone_association == null ? "yes" : var.include_route53_zone_association
  include_nat_gateways             = var.include_nat_gateways == null ? "yes" : var.include_nat_gateways
}

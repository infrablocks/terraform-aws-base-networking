module "base_network" {
  source = "../../../../"

  vpc_cidr = var.vpc_cidr
  region = var.region
  availability_zones = var.availability_zones

  public_subnets_offset = var.public_subnets_offset
  private_subnets_offset = var.private_subnets_offset

  component = var.component
  deployment_identifier = var.deployment_identifier
  dependencies = var.dependencies

  include_route53_zone_association = var.include_route53_zone_association
  private_zone_id = var.private_zone_id

  include_nat_gateways = var.include_nat_gateways
}

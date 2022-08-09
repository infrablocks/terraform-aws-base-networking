module "base_network" {
  # This makes absolutely no sense. I think there's a bug in terraform.
  source = "./../../../../../../../"

  vpc_cidr = var.vpc_cidr
  region = var.region
  availability_zones = var.availability_zones

  public_subnets_offset = var.public_subnets_offset
  private_subnets_offset = var.private_subnets_offset

  component = var.component
  deployment_identifier = var.deployment_identifier
  dependencies = var.dependencies

  include_route53_zone_association = var.include_route53_zone_association
  private_zone_id = module.dns_zones.private_zone_id

  include_nat_gateways = var.include_nat_gateways
}

module "dns_zones" {
  source = "infrablocks/dns-zones/aws"
  version = "1.0.0"

  domain_name = "infrablocks-ecs-cluster-example.com"
  private_domain_name = "infrablocks-ecs-cluster-example.net"
  private_zone_vpc_id = var.private_zone_vpc_id
  private_zone_vpc_region = var.region
}

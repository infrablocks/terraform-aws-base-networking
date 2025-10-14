module "base_networking" {
  source = "../../"

  component             = var.component
  deployment_identifier = var.deployment_identifier

  region             = var.region
  availability_zones = var.availability_zones
  vpc_cidr           = var.vpc_cidr

  dependencies = ["other_vpc_1", "other_vpc_2"]

  private_zone_id = module.dns_zones.private_zone_id
}

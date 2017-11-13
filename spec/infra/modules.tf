module "base_network" {
  source = "../../../src"

  vpc_cidr = "${var.vpc_cidr}"
  region = "${var.region}"
  availability_zones = "${var.availability_zones}"

  public_subnets_offset = "${var.public_subnets_offset}"
  private_subnets_offset = "${var.private_subnets_offset}"

  component = "${var.component}"
  deployment_identifier = "${var.deployment_identifier}"
  dependencies = "${var.dependencies}"

  private_zone_id = "${var.private_zone_id}"

  infrastructure_events_bucket = "${var.infrastructure_events_bucket}"
}
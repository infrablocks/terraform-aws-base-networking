resource "aws_default_vpc" "default" {}

module "dns_zones" {
  source = "infrablocks/dns-zones/aws"
  version = "2.0.0"

  domain_name = var.domain_name
  private_domain_name = var.domain_name
  private_zone_vpc_id = aws_default_vpc.default.id
  private_zone_vpc_region = var.region
}

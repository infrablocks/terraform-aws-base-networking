resource "aws_vpc" "base" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = "true"

  tags {
    Name = "vpc-${var.component}-${var.deployment_identifier}"
    Component = "${var.component}"
    DeploymentIdentifier = "${var.deployment_identifier}"
  }
}

resource "aws_route53_zone_association" "base" {
  zone_id = "${var.private_zone_id}"
  vpc_id = "${aws_vpc.base.id}"
}

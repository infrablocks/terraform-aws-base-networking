resource "aws_vpc" "base" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = "true"

  tags {
    Name = "vpc-${var.component}-${var.deployment_identifier}"
    Component = "${var.component}"
    DeploymentIdentifier = "${var.deployment_identifier}"
  }
}
resource "aws_vpc" "base" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = "true"

  tags = {
    Name = "vpc-${var.component}-${var.deployment_identifier}"
    Component = "${var.component}"
    DeploymentIdentifier = "${var.deployment_identifier}"
    Dependencies = "${var.dependencies}"
  }
}

resource "aws_route53_zone_association" "base" {
  count = "${var.include_route53_zone_association == "yes" ? 1 : 0}"
  zone_id = "${var.private_zone_id}"
  vpc_id = "${aws_vpc.base.id}"
}

resource "aws_s3_bucket_object" "vpc_lifecycle_event" {
  bucket = "${var.infrastructure_events_bucket}"
  key = "vpc-existence/${aws_vpc.base.id}"
  content = "${aws_vpc.base.id}"

  count = "${var.include_lifecycle_events == "yes" ? 1 : 0}"

  depends_on = [
    "aws_subnet.public",
    "aws_subnet.private",
    "aws_route_table.public",
    "aws_route_table.private"
  ]
}
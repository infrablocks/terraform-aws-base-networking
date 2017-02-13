resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.base.id}"
  count = "${length(split(",", var.availability_zones))}"
  cidr_block = "${cidrsubnet(var.vpc_cidr, 8, count.index)}"
  availability_zone = "${element(split (",", var.availability_zones), count.index)}"

  tags {
    Name = "public-subnet-${var.component}-${var.deployment_identifier}-${element(split (",", var.availability_zones), count.index)}"
    Component = "${var.component}"
    DeploymentIdentifier = "${var.deployment_identifier}"
    Tier = "public"
  }
}
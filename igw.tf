resource "aws_internet_gateway" "base_igw" {
  vpc_id = "${aws_vpc.base.id}"

  tags = {
    Name = "igw-${var.component}-${var.deployment_identifier}"
    Component = "${var.component}"
    DeploymentIdentifier = "${var.deployment_identifier}"
    Tier = "public"
  }
}
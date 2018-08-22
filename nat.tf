resource "aws_eip" "nat" {
  count = "${var.include_nat_gateway == "yes" ? 1 : 0}"

  vpc = true

  tags {
    Name = "eip-nat-${var.component}-${var.deployment_identifier}"
    Component = "${var.component}"
    DeploymentIdentifier = "${var.deployment_identifier}"
  }
}

resource "aws_nat_gateway" "base" {
  count = "${var.include_nat_gateway == "yes" ? 1 : 0}"

  allocation_id = "${element(concat(aws_eip.nat.*.id, list("")), 0)}"
  subnet_id = "${aws_subnet.public.0.id}"

  depends_on = [
    "aws_internet_gateway.base_igw"
  ]
}

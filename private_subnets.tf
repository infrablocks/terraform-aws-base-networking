resource "aws_subnet" "private" {
  vpc_id = "${aws_vpc.base.id}"
  count = "${length(split(",", var.availability_zones))}"
  cidr_block = "${cidrsubnet(var.vpc_cidr, 8, count.index + length(split(",", var.availability_zones)) + var.private_subnets_offset)}"
  availability_zone = "${element(split (",", var.availability_zones), count.index)}"

  tags {
    Name = "private-subnet-${var.component}-${var.deployment_identifier}-${element(split (",", var.availability_zones) ,count.index)}"
    Component = "${var.component}"
    DeploymentIdentifier = "${var.deployment_identifier}"
    Tier = "private"
  }
}

resource "aws_route_table" "private" {
  vpc_id = "${aws_vpc.base.id}"

  tags {
    Name = "private-routetable-${var.component}-${var.deployment_identifier}"
    Component = "${var.component}"
    DeploymentIdentifier = "${var.deployment_identifier}"
    Tier = "private"
  }
}

resource "aws_route" "private_internet" {
  route_table_id = "${aws_route_table.private.id}"
  nat_gateway_id = "${aws_nat_gateway.base.id}"
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private" {
  count = "${length(split(",",var.availability_zones))}"
  subnet_id = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${aws_route_table.private.id}"
}

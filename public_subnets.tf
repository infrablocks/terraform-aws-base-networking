resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.base.id}"
  count = "${length(split(",", var.availability_zones))}"
  cidr_block = "${cidrsubnet(var.vpc_cidr, 8, count.index + var.public_subnets_offset)}"
  availability_zone = "${element(split (",", var.availability_zones), count.index)}"

  tags {
    Name = "public-subnet-${var.component}-${var.deployment_identifier}-${element(split (",", var.availability_zones), count.index)}"
    Component = "${var.component}"
    DeploymentIdentifier = "${var.deployment_identifier}"
    Tier = "public"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.base.id}"

  tags {
    Name = "public-routetable-${var.component}-${var.deployment_identifier}"
    Component = "${var.component}"
    DeploymentIdentifier = "${var.deployment_identifier}"
    Tier = "public"
  }
}

resource "aws_route" "public_internet" {
  route_table_id = "${aws_route_table.public.id}"
  gateway_id = "${aws_internet_gateway.base_igw.id}"
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public" {
  count = "${length(split(",", var.availability_zones))}"
  subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_subnet" "private" {
  for_each = toset(var.availability_zones)

  vpc_id = aws_vpc.base.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, index(var.availability_zones, each.value) + length(var.availability_zones) + local.private_subnets_offset)
  availability_zone = each.value

  tags = {
    Name = "private-subnet-${var.component}-${var.deployment_identifier}-${each.value}"
    Component = var.component
    DeploymentIdentifier = var.deployment_identifier
    Tier = "private"
  }
}

resource "aws_route_table" "private" {
  for_each = toset(var.availability_zones)

  vpc_id = aws_vpc.base.id

  tags = {
    Name = "private-routetable-${var.component}-${var.deployment_identifier}-${each.value}"
    Component = var.component
    DeploymentIdentifier = var.deployment_identifier
    Tier = "private"
  }
}

resource "aws_route" "private_internet" {
  for_each = local.include_nat_gateways == "yes" ? toset(var.availability_zones) : toset([])

  route_table_id = aws_route_table.private[each.value].id
  nat_gateway_id = aws_nat_gateway.base[each.value].id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private" {
  for_each = toset(var.availability_zones)

  subnet_id = aws_subnet.private[each.value].id
  route_table_id = aws_route_table.private[each.value].id
}

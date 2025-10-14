resource "aws_subnet" "private" {
  for_each = local.az_map

  vpc_id            = aws_vpc.base.id
  cidr_block        = each.value.private_subnet_cidr
  availability_zone = each.value.zone

  tags = {
    Name                 = "private-subnet-${var.component}-${var.deployment_identifier}-${each.value.zone}"
    Component            = var.component
    DeploymentIdentifier = var.deployment_identifier
    Tier                 = "private"
  }
}

resource "aws_route_table" "private" {
  for_each = local.az_map

  vpc_id = aws_vpc.base.id

  tags = {
    Name                 = "private-routetable-${var.component}-${var.deployment_identifier}-${each.value.zone}"
    Component            = var.component
    DeploymentIdentifier = var.deployment_identifier
    Tier                 = "private"
  }
}

resource "aws_route" "private_internet" {
  for_each = local.include_nat_gateways == "yes" ? local.az_map : {}

  route_table_id         = aws_route_table.private[each.key].id
  nat_gateway_id         = aws_nat_gateway.base[each.key].id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private" {
  for_each = local.az_map

  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

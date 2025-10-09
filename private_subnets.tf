resource "aws_subnet" "private" {
  for_each = var.availability_zones

  vpc_id = aws_vpc.base.id
  cidr_block = each.value.cidr_private != null ? each.value.cidr_private : cidrsubnet(
    var.vpc_cidr,
    8,
    index(keys(var.availability_zones), each.key) + length(var.availability_zones) + local.private_subnets_offset
  )
  availability_zone = each.key

  tags = {
    Name = "private-subnet-${var.component}-${var.deployment_identifier}-${each.key}"
    Component = var.component
    DeploymentIdentifier = var.deployment_identifier
    Tier = "private"
  }
}

resource "aws_route_table" "private" {
  for_each = var.availability_zones

  vpc_id = aws_vpc.base.id

  tags = {
    Name = "private-routetable-${var.component}-${var.deployment_identifier}-${each.key}"
    Component = var.component
    DeploymentIdentifier = var.deployment_identifier
    Tier = "private"
  }
}

resource "aws_route" "private_internet" {
  for_each = local.include_nat_gateways == "yes" ? var.availability_zones : {}

  route_table_id = aws_route_table.private[each.key].id
  nat_gateway_id = aws_nat_gateway.base[each.key].id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private" {
  for_each = var.availability_zones

  subnet_id = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

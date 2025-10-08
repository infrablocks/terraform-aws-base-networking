resource "aws_subnet" "public" {
  for_each = toset(var.availability_zones)

  vpc_id = aws_vpc.base.id
  cidr_block = cidrsubnet(var.vpc_cidr, 8, index(var.availability_zones, each.value) + local.public_subnets_offset)
  availability_zone = each.value

  tags = {
    Name = "public-subnet-${var.component}-${var.deployment_identifier}-${each.value}"
    Component = var.component
    DeploymentIdentifier = var.deployment_identifier
    Tier = "public"
  }
}

resource "aws_route_table" "public" {
  for_each = toset(var.availability_zones)

  vpc_id = aws_vpc.base.id

  tags = {
    Name = "public-routetable-${var.component}-${var.deployment_identifier}-${each.value}"
    Component = var.component
    DeploymentIdentifier = var.deployment_identifier
    Tier = "public"
  }
}

resource "aws_route" "public_internet" {
  for_each = toset(var.availability_zones)

  route_table_id = aws_route_table.public[each.value].id
  gateway_id = aws_internet_gateway.base_igw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public" {
  for_each = toset(var.availability_zones)

  subnet_id = aws_subnet.public[each.value].id
  route_table_id = aws_route_table.public[each.value].id
}

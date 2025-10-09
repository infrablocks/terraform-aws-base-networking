resource "aws_subnet" "public" {
  for_each = var.availability_zones

  vpc_id = aws_vpc.base.id
  cidr_block = each.value.cidr_public != null ? each.value.cidr_public : cidrsubnet(
    var.vpc_cidr,
    8,
    index(keys(var.availability_zones), each.key) + local.public_subnets_offset
  )
  availability_zone = each.key

  tags = {
    Name = "public-subnet-${var.component}-${var.deployment_identifier}-${each.key}"
    Component = var.component
    DeploymentIdentifier = var.deployment_identifier
    Tier = "public"
  }
}

resource "aws_route_table" "public" {
  for_each = var.availability_zones

  vpc_id = aws_vpc.base.id

  tags = {
    Name = "public-routetable-${var.component}-${var.deployment_identifier}-${each.key}"
    Component = var.component
    DeploymentIdentifier = var.deployment_identifier
    Tier = "public"
  }
}

resource "aws_route" "public_internet" {
  for_each = var.availability_zones

  route_table_id = aws_route_table.public[each.key].id
  gateway_id = aws_internet_gateway.base_igw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "public" {
  for_each = var.availability_zones

  subnet_id = aws_subnet.public[each.key].id
  route_table_id = aws_route_table.public[each.key].id
}

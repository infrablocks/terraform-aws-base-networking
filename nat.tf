resource "aws_eip" "nat" {
  for_each = local.include_nat_gateways == "yes" ? toset(var.availability_zones) : toset([])

  vpc = true

  tags = {
    Name = "eip-nat-${var.component}-${var.deployment_identifier}-${each.value}"
    Component = var.component
    DeploymentIdentifier = var.deployment_identifier
  }
}

resource "aws_nat_gateway" "base" {
  for_each = local.include_nat_gateways == "yes" ? toset(var.availability_zones) : toset([])

  allocation_id = aws_eip.nat[each.value].id
  subnet_id = aws_subnet.public[each.value].id

  depends_on = [
    aws_internet_gateway.base_igw
  ]

  tags = {
    Name = "nat-${var.component}-${var.deployment_identifier}-${each.value}"
    Component = var.component
    DeploymentIdentifier = var.deployment_identifier
  }
}

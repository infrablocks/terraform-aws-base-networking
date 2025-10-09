resource "aws_eip" "nat" {
  for_each = local.include_nat_gateways == "yes" ? var.availability_zones : {}

  vpc = true
  # domain = "vpc"

  tags = {
    Name = "eip-nat-${var.component}-${var.deployment_identifier}-${each.key}"
    Component = var.component
    DeploymentIdentifier = var.deployment_identifier
  }
}

resource "aws_nat_gateway" "base" {
  for_each = local.include_nat_gateways == "yes" ? var.availability_zones : {}

  allocation_id = aws_eip.nat[each.key].id
  subnet_id = aws_subnet.public[each.key].id

  depends_on = [
    aws_internet_gateway.base_igw
  ]

  tags = {
    Name = "nat-${var.component}-${var.deployment_identifier}-${each.key}"
    Component = var.component
    DeploymentIdentifier = var.deployment_identifier
  }
}

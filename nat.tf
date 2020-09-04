resource "aws_eip" "nat" {
  count = var.include_nat_gateways == "yes" ? length(var.availability_zones) : 0

  vpc = true

  tags = {
    Name = "eip-nat-${var.component}-${var.deployment_identifier}-${element(var.availability_zones, count.index)}"
    Component = var.component
    DeploymentIdentifier = var.deployment_identifier
  }
}

resource "aws_nat_gateway" "base" {
  count = var.include_nat_gateways == "yes" ? length(var.availability_zones) : 0

  allocation_id = element(aws_eip.nat.*.id, count.index)
  subnet_id = element(aws_subnet.public.*.id, count.index)

  depends_on = [
    aws_internet_gateway.base_igw
  ]

  tags = {
    Name = "nat-${var.component}-${var.deployment_identifier}-${element(var.availability_zones, count.index)}"
    Component = var.component
    DeploymentIdentifier = var.deployment_identifier
  }
}

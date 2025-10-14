output "vpc_id" {
  description = "The ID of the created VPC."
  value       = aws_vpc.base.id
}

output "vpc_cidr" {
  description = "The CIDR of the created VPC."
  value       = aws_vpc.base.cidr_block
}

output "availability_zones" {
  description = "The availability zones in which subnets were created."
  value       = local.availability_zones
}

output "number_of_availability_zones" {
  description = "The number of populated availability zones available."
  value       = length(local.availability_zones)
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets."
  value       = [for az in local.availability_zones : aws_subnet.public[az].id]
}

output "public_subnet_cidr_blocks" {
  description = "The CIDRs of the public subnets."
  value       = [for az in local.availability_zones : aws_subnet.public[az].cidr_block]
}

output "public_route_table_ids" {
  description = "The IDs of the public route tables."
  value       = [for az in local.availability_zones : aws_route_table.public[az].id]
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets."
  value       = [for az in local.availability_zones : aws_subnet.private[az].id]
}

output "private_subnet_cidr_blocks" {
  description = "The CIDRs of the private subnets."
  value       = [for az in local.availability_zones : aws_subnet.private[az].cidr_block]
}

output "private_route_table_ids" {
  description = "The IDs of the private route tables."
  value       = [for az in local.availability_zones : aws_route_table.private[az].id]
}

output "nat_public_ips" {
  description = "The EIPs attached to the NAT gateways."
  value       = local.include_nat_gateways == "yes" ? [for az in local.availability_zones : aws_eip.nat[az].public_ip] : []
}

output "internet_gateway_id" {
  description = "The ID of IGW attached to the VPC."
  value       = aws_internet_gateway.base_igw.id
}

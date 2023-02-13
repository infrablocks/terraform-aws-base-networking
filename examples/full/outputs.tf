output "public_zone_id" {
  value = module.dns_zones.public_zone_id
}

output "private_zone_id" {
  value = module.dns_zones.private_zone_id
}

output "vpc_id" {
  value = module.base_networking.vpc_id
}

output "vpc_cidr" {
  value = module.base_networking.vpc_cidr
}

output "availability_zones" {
  value = module.base_networking.availability_zones
}

output "number_of_availability_zones" {
  value = module.base_networking.number_of_availability_zones
}

output "public_subnet_ids" {
  value = module.base_networking.public_subnet_ids
}

output "public_subnet_cidr_blocks" {
  value = module.base_networking.public_subnet_cidr_blocks
}

output "public_route_table_ids" {
  value = module.base_networking.public_route_table_ids
}

output "private_subnet_ids" {
  value = module.base_networking.private_subnet_ids
}

output "private_subnet_cidr_blocks" {
  value = module.base_networking.private_subnet_cidr_blocks
}

output "private_route_table_ids" {
  value = module.base_networking.private_route_table_ids
}

output "nat_public_ips" {
  value = module.base_networking.nat_public_ips
}

output "internet_gateway_id" {
  value = module.base_networking.internet_gateway_id
}

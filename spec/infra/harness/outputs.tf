output "vpc_id" {
  value = "${module.base_network.vpc_id}"
}

output "vpc_cidr" {
  value = "${module.base_network.vpc_cidr}"
}

output "availability_zones" {
  value = "${module.base_network.availability_zones}"
}

output "number_of_availability_zones" {
  value = "${module.base_network.number_of_availability_zones}"
}

output "public_subnet_ids" {
  value = "${module.base_network.public_subnet_ids}"
}

output "public_subnet_cidr_blocks" {
  value = "${module.base_network.public_subnet_cidr_blocks}"
}

output "public_route_table_id" {
  value = "${module.base_network.public_route_table_id}"
}

output "private_subnet_ids" {
  value = "${module.base_network.private_subnet_ids}"
}

output "private_subnet_cidr_blocks" {
  value = "${module.base_network.private_subnet_cidr_blocks}"
}

output "private_route_table_id" {
  value = "${module.base_network.private_route_table_id}"
}

output "nat_public_ip" {
  value = "${module.base_network.nat_public_ip}"
}

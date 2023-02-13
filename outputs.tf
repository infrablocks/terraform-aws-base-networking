output "vpc_id" {
  description = "The ID of the created VPC."
  value = "${element(concat(aws_vpc.base.*.id, list("")), 0)}"
}

output "vpc_cidr" {
  description = "The CIDR of the created VPC."
  value = "${element(concat(aws_vpc.base.*.cidr_block, list("")), 0)}"
}

output "availability_zones" {
  description = "The availability zones in which subnets were created."
  value = "${var.availability_zones}"
}

output "number_of_availability_zones" {
  description = "The number of populated availability zones available."
  value = "${length(split(",",var.availability_zones))}"
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets."
  value = "${join(",", aws_subnet.public.*.id)}"
}

output "public_subnet_cidr_blocks" {
  description = "The CIDRs of the public subnets."
  value = "${join(",", aws_subnet.public.*.cidr_block)}"
}

output "public_route_table_id" {
  description = "The ID of the public route table."
  value = "${element(concat(aws_route_table.public.*.id, list("")), 0)}"
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets."
  value = "${join(",", aws_subnet.private.*.id)}"
}

output "private_subnet_cidr_blocks" {
  description = "The CIDRs of the private subnets."
  value = "${join(",", aws_subnet.private.*.cidr_block)}"
}

output "private_route_table_id" {
  description = "The ID of the private route table."
  value = "${element(concat(aws_route_table.private.*.id, list("")), 0)}"
}

output "nat_public_ip" {
  description = "The EIP attached to the NAT."
  value = "${element(concat(aws_eip.nat.*.public_ip, list("")), 0)}"
}

output "internet_gateway_id" {
  description = "The ID of IGW attached to the VPC."
  value = aws_internet_gateway.base_igw.id
}

output "vpc_id" {
  value = "${aws_vpc.base.id}"
}

output "vpc_cidr" {
  value = "${aws_vpc.base.cidr_block}"
}

output "availability_zones" {
  value = "${var.availability_zones}"
}

output "number_of_availability_zones" {
  value = "${length(split(",",var.availability_zones))}"
}

output "public_subnet_ids" {
  value = "${join(",", aws_subnet.public.*.id)}"
}

output "public_subnet_cidr_blocks" {
  value = "${join(",", aws_subnet.public.*.cidr_block)}"
}

output "public_route_table_id" {
  value = "${aws_route_table.public.id}"
}

output "private_subnet_ids" {
  value = "${join(",", aws_subnet.private.*.id)}"
}

output "private_subnet_cidr_blocks" {
  value = "${join(",", aws_subnet.private.*.cidr_block)}"
}

output "private_route_table_id" {
  value = "${aws_route_table.private.id}"
}

output "bastion_public_ip" {
  value = "${aws_eip.bastion.public_ip}"
}

output "nat_public_ip" {
  value = "${aws_eip.nat.public_ip}"
}

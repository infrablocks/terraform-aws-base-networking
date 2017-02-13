output "vpc_id" {
  value = "${aws_vpc.base.id}"
}

output "vpc_cidr" {
  value = "${aws_vpc.base.cidr_block}"
}

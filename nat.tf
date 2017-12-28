resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "base" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id = "${aws_subnet.public.0.id}"

  depends_on = [
    "aws_internet_gateway.base_igw"
  ]
}

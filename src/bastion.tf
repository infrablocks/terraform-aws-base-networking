resource "aws_key_pair" "bastion" {
  key_name = "bastion-${var.component}-${var.deployment_identifier}"
  public_key = "${file(var.bastion_ssh_public_key_path)}"
}

resource "aws_instance" "bastion" {
  ami = "${var.bastion_ami}"
  instance_type = "${var.bastion_instance_type}"
  key_name = "${aws_key_pair.bastion.key_name}"
  subnet_id = "${aws_subnet.public.0.id}"

  vpc_security_group_ids = [
    "${aws_security_group.bastion.id}"
  ]

  tags {
    Name = "bastion-${var.component}-${var.deployment_identifier}"
    Component = "${var.component}"
    DeploymentIdentifier = "${var.deployment_identifier}"
    Role = "bastion"
  }
}

resource "aws_eip" "bastion" {
  vpc = true
  instance = "${aws_instance.bastion.id}"
}

resource "aws_route53_record" "bastion" {
  zone_id = "${var.public_zone_id}"
  name = "bastion-${var.component}-${var.deployment_identifier}.${var.domain_name}"
  type = "A"
  ttl = "60"
  records = [
    "${aws_eip.bastion.public_ip}"
  ]
}

resource "aws_security_group" "bastion" {
  name = "bastion-${var.component}-${var.deployment_identifier}"
  vpc_id = "${aws_vpc.base.id}"

  tags {
    Name = "bastion-sg-${var.component}-${var.deployment_identifier}"
    Component = "${var.component}"
    DeploymentIdentifier = "${var.deployment_identifier}"
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "${split(",", var.bastion_ssh_allow_cidrs)}"
    ]
  }

  egress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [
      "${var.vpc_cidr}"
    ]
  }
}

resource "aws_security_group" "open_to_bastion" {
  name = "open-to-bastion-${var.component}-${var.deployment_identifier}"
  vpc_id = "${aws_vpc.base.id}"

  tags {
    Name = "open-to-bastion-sg-${var.component}-${var.deployment_identifier}"
    Component = "${var.component}"
    DeploymentIdentifier = "${var.deployment_identifier}"
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = [
      "${aws_security_group.bastion.id}"
    ]
  }
}
## Unreleased

BACKWARDS INCOMPATIBILITIES / NOTES:

* `for_each` is used instead of `count` for creating resources for each 
  availability zone, so the availability zone will be used as the resource key, 
  not an index. 

  As a consequence, if resources have been created with a 
  previous version of this module, they will need to be `moved` to avoid them
  being destroyed and recreated.

  e.g.

  ```terraform
     moved {
       from = module.base-network.aws_subnet.public[0]
       to   = module.base-network.aws_subnet.public["eu-west-1a"]
     }
  
     moved {
       from = module.base-network.aws_subnet.private[0]
       to   = module.base-network.aws_subnet.private["eu-west-1a"]
     }
  
     # etc..
  ```


* The default value for the `private_subnets_offset` variable has been changed
  from 0 to 128.  This means that if the offsets are not provided, there will
  be sufficient space between the private and public CIDR blocks such that new 
  availability_zones can be added without needing to destroy existing private 
  subnets.

ENHANCEMENTS

* As an alternative to the `availability_zones` variable, an
  `availability_zone_configuration` variable is also supported, which takes a 
  list of objects with the keys `zone`, `public_subnet_cidr` and
  `private_subnet_cidr`. This can be useful in cases where a new availability
  zone is being added, but inference of the CIDR blocks could result in existing
  subnets being destroyed and recreated, in which case the existing public and 
  private subnet CIDRs can be explicitly supplied to prevent this. 

## 5.1.0 (13th Feb 2023)

ENHANCEMENTS

* This module now outputs the ID of the created IGW.

## 5.0.0 (28th Dec 2022)

ENHANCEMENTS

* This module can now be used with version 4 of the AWS provider.

BACKWARDS INCOMPATIBILITIES / NOTES:

* This module is now compatible with Terraform 1.0 and higher.

## 4.0.0 (27th May 2021)

BACKWARDS INCOMPATIBILITIES / NOTES:

* This module is now compatible with Terraform 0.14 and higher.

## 3.0.0 (5th September 2020)

BACKWARDS INCOMPATIBILITIES / NOTES:

* Prior to this version, the module created a single NAT gateway routed to by
  all private subnets. This created a single point of failure in the case of an
  availability zone outage of the zone in which the NAT gateway resided. The
  module now creates a NAT gateway per availability zone, which also 
  necessitates a route table per availability zone. 
  
  As a result, applying this version of the module will destroy both the public 
  and private route tables in the network and then recreate a public and 
  private route table for each availability zone. Any additional routes added 
  to the existing route tables must be readded to each of the newly created 
  route tables.
  
  Additionally, where previously single valued `public_route_table_id`, 
  `private_route_table_id` and `nat_public_ip` outputs were produced, now array
  valued `public_route_table_ids`, `private_route_table_ids` and 
  `nat_public_ips` outputs are produced.

## 2.0.0 (5th December 2019)

BACKWARDS INCOMPATIBILITIES / NOTES:

* The `infrastructure_events_bucket` variable, the `include_lifecycle_events` 
  variable and the `aws_s3_bucket_object` representing the VPC lifecycle event 
  have been removed from this module and are now encapsulated into the 
  `terraform-aws-vpc-lifecycle-event` module. This is to allow the lifecycle 
  events bucket to be in a different account to the VPC.

## 1.1.0 (28th November 2019)

BUG FIXES:

* Upgrade to avoid vulnerability in test library

## 1.0.0 (18th November 2019)

ENHANCEMENTS:

* Make use of more recent module improvements such as list inputs and outputs.
* Fully convert to HCL 2.

BACKWARDS INCOMPATIBILITIES / NOTES:

* The `availability_zones` and `dependencies` inputs are now lists of strings.
* The `availability_zones`, `public_subnet_ids`, `public_subnet_cidr_blocks`,
  `private_subnet_ids` and `private_subnet_cidr_blocks` outputs are now all 
  lists of strings.

## 0.2.0 (25th April 2018)

ENHANCEMENTS:

* Make NAT gateway optional.

## 0.1.17 (December 28th, 2017)

BACKWARDS INCOMPATIBILITIES / NOTES:

* The configuration directory has changed from `<repo>/src` to `<repo>` to
  satisfy the terraform standard module structure.
  
ENHANCEMENTS:

* All variables and outputs now have descriptions to satisfy the terraform
  standard module structure. 

## 0.1.11 (October 5th, 2017)

BACKWARDS INCOMPATIBILITIES / NOTES:

* This version extracts the bastion into a separate 
  [bastion module](https://github.com/infrablocks/terraform-aws-bastion) which
  allows networks to be deployed with or without a bastion or for a bastion to
  be shared across networks. The bastion module also uses an autoscaling group
  to ensure the bastion remains available. As such, it will require a load
  balancer in order to be given a DNS name.

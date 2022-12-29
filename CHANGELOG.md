## Unreleased

## 4.0.0 (28th Dec 2022)

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

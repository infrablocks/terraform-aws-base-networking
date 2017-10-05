## 0.1.11 (October 5th, 2017)

BACKWARDS INCOMPATIBILITIES / NOTES:

* This version extracts the bastion into a separate 
  [bastion module](https://github.com/infrablocks/terraform-aws-bastion) which
  allows networks to be deployed with or without a bastion or for a bastion to
  be shared across networks. The bastion module also uses an autoscaling group
  to ensure the bastion remains available. As such, it will require a load
  balancer in order to be given a DNS name.

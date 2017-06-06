Terraform AWS Base Networking
=============================

A Terraform module for building a base network in AWS.

The network consists of:
* Public and private subnets for each supplied availability zone
* A NAT gateway for outbound Internet connectivity
* Routes from the public subnets to the Internet gateway
* Routes from the private subnets to the NAT
* A bastion host configured with the supplied SSH key
* A security group for the bastion limited to the supplied IP ranges
* A DNS entry in the supplied public zone for the bastion
* Standard tags for all resources
* A notification (in the form of an S3 object) in an S3 bucket on VPC creation
  (optional)

![Diagram of infrastructure managed by this module](/docs/architecture.png?raw=true)

Usage
-----

To use the module, include something like the following in your terraform configuration:

```hcl-terraform
module "base-network" {
  source = "git@github.com:tobyclemson/terraform-aws-base-networking.git//src"
  
  vpc_cidr = "10.0.0.0/16"
  region = "eu-west-2"
  availability_zones = "eu-west-2a,eu-west-2b"
  
  component = "important-component"
  deployment_identifier = "production"
  
  bastion_ami = "ami-bb373ddf"
  bastion_ssh_public_key_path = "~/.ssh/id_rsa.pub"
  bastion_ssh_allow_cidrs = "100.10.10.0/24,200.20.0.0/16"
  
  domain_name = "example.com"
  public_zone_id = "Z1WA3EVJBXSQ2V"
  private_zone_id = "Z3CVA9QD5NHSW3"
}
```

Executing `terraform get` will fetch the module.


### Inputs

| Name                         | Description                                        | Default | Required                           |
|------------------------------|----------------------------------------------------|:-------:|:----------------------------------:|
| vpc_cidr                     | The CIDR to use for the VPC                        | -       | yes                                |
| region                       | The region into which to deploy the VPC            | -       | yes                                |
| availability_zones           | The availability zones for which to add subnets    | -       | yes                                |
| component                    | The component this network will contain            | -       | yes                                |
| deployment_identifier        | An identifier for this instantiation               | -       | yes                                |
| bastion_ami                  | The AMI to use for the bastion instance            | -       | yes                                |
| bastion_instance_type        | The instance type to use for the bastion instance  | t2.nano | yes                                |
| bastion_ssh_public_key_path  | The path to the public key to use for the bastion  | -       | yes                                |
| bastion_ssh_allow_cidrs      | The CIDRs from which the bastion is reachable      | -       | yes                                |
| domain_name                  | The domain name of the supplied Route 53 zone      | -       | yes                                |
| public_zone_id               | The ID of the public Route 53 zone                 | -       | yes                                |
| private_zone_id              | The ID of the private Route 53 zone                | -       | yes                                |
| include_lifecycle_events     | Whether or not to notify via S3 of a created VPC   | yes     | yes                                |
| infrastructure_events_bucket | S3 bucket in which to put VPC creation events      | -       | if include_lifecycle_events is yes |


### Outputs

| Name                              | Description                                          |
|-----------------------------------|------------------------------------------------------|
| vpc_id                            | The ID of the created VPC                            |
| vpc_cidr                          | The CIDR of the created VPC                          |
| availability_zones                | The availability zones in which subnets were created |
| number_of_availability_zones      | The number of populated availability zones available |
| public_subnet_ids                 | The IDs of the public subnets                        |
| public_subnet_cidrs               | The CIDRs of the public subnets                      |
| private_subnet_ids                | The IDs of the private subnets                       |
| private_subnet_cidrs              | The CIDRs of the private subnets                     |
| bastion_public_ip                 | The EIP attached to the bastion                      |
| nat_public_ip                     | The EIP attached to the NAT                          |
| open_to_bastion_security_group_id | The ID for the open-to-bastion security group        |


Development
-----------

### Machine Requirements

In order for the build to run correctly, a few tools will need to be installed on your
development machine:

* Ruby (2.3.1)
* Bundler
* git
* git-crypt
* gnupg
* direnv

#### Mac OS X Setup

Installing the required tools is best managed by [homebrew](http://brew.sh).

To install homebrew:

```
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Then, to install the required tools:

```
# ruby
brew install rbenv
brew install ruby-build
echo 'eval "$(rbenv init - bash)"' >> ~/.bash_profile
echo 'eval "$(rbenv init - zsh)"' >> ~/.zshrc
eval "$(rbenv init -)"
rbenv install 2.3.1
rbenv rehash
rbenv local 2.3.1
gem install bundler

# git, git-crypt, gnupg
brew install git
brew install git-crypt
brew install gnupg

# direnv
brew install direnv
echo "$(direnv hook bash)" >> ~/.bash_profile
echo "$(direnv hook zsh)" >> ~/.zshrc
eval "$(direnv hook $SHELL)"

direnv allow <repository-directory>
```

### Running the build

To provision module infrastructure, run tests and then destroy that infrastructure,
execute:

```bash
./go
```

To provision the module contents:

```bash
./go provision:aws[<deployment_identifier>]
```

To destroy the module contents:

```bash
./go destroy:aws[<deployment_identifier>]
```

### Common Tasks

To generate an SSH key pair:

```
ssh-keygen -t rsa -b 4096 -C integration-test@example.com -N '' -f config/secrets/keys/bastion/ssh
```

Contributing
------------

Bug reports and pull requests are welcome on GitHub at https://github.com/tobyclemson/terraform-aws-base-networking. 
This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to 
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


License
-------

The library is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).



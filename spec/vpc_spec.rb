require 'spec_helper'

describe 'VPC' do
  include_context :terraform

  subject { vpc("vpc-#{variables.component}-#{variables.deployment_identifier}") }

  let :private_hosted_zone do
    route53_client.get_hosted_zone({id: variables.private_zone_id})
  end

  it { should exist }
  it { should have_tag('Component').value(variables.component) }
  it { should have_tag('DeploymentIdentifier').value(variables.deployment_identifier) }

  its(:cidr_block) { should eq variables.vpc_cidr }

  it 'exposes the VPC ID as an output' do
    expected_vpc_id = subject.vpc_id
    actual_vpc_id = Terraform.output(name: 'vpc_id')

    expect(actual_vpc_id).to(eq(expected_vpc_id))
  end

  it 'exposes the VPC CIDR block as an output' do
    expected_vpc_cidr = subject.cidr_block
    actual_vpc_cidr = Terraform.output(name: 'vpc_cidr')

    expect(actual_vpc_cidr).to(eq(expected_vpc_cidr))
  end

  it 'enables DNS hostnames' do
    full_resource = Aws::EC2::Vpc.new(subject.id)
    dns_hostnames = full_resource.describe_attribute({attribute: 'enableDnsHostnames'})

    expect(dns_hostnames.enable_dns_hostnames.value).to be(true)
  end

  it 'exposes the availability zones as an output' do
    expected_availability_zones = variables.availability_zones
    actual_availability_zones = Terraform.output(name: 'availability_zones')

    expect(actual_availability_zones).to(eq(expected_availability_zones))
  end

  it 'exposes the number of availability zones as an output' do
    expected_count = variables.availability_zones.split(',').count.to_s
    actual_count = Terraform.output(name: 'number_of_availability_zones')

    expect(actual_count).to(eq(expected_count))
  end

  it 'associates the supplied private hosted with the VPC' do
    expect(private_hosted_zone.vp_cs.map(&:vpc_id)).to(include(subject.id))
  end
end
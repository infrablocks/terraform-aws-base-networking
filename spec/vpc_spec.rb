require 'spec_helper'

describe 'VPC' do
  include_context :terraform

  subject { vpc("vpc-#{variables.component}-#{variables.deployment_identifier}") }

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
end
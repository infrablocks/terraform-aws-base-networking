require 'spec_helper'

describe 'public subnet creation' do
  include_context :terraform

  let :created_vpc do
    vpc("vpc-#{variables.component}-#{variables.deployment_identifier}")
  end
  let :subnets do
    variables.availability_zones.split(',').map do |zone|
      subnet("public-subnet-#{variables.component}-#{variables.deployment_identifier}-#{zone}")
    end
  end

  it 'has a Component tag on each subnet' do
    subnets.each do |subnet|
      expect(subnet).to(have_tag('Component').value(variables.component))
    end
  end

  it 'has a DeploymentIdentifier tag on each subnet' do
    subnets.each do |subnet|
      expect(subnet).to(have_tag('DeploymentIdentifier')
                            .value(variables.deployment_identifier))
    end
  end

  it 'has a Tier of public on each subnet' do
    subnets.each do |subnet|
      expect(subnet).to(have_tag('Tier').value('public'))
    end
  end

  it 'associates each subnet with the created VPC' do
    subnets.each do |subnet|
      expect(subnet.vpc_id)
          .to(eq(created_vpc.id))
    end
  end

  it 'distributes subnets across availability zones' do
    variables.availability_zones.split(',').map do |zone|
      expect(subnets.map(&:availability_zone)).to(include(zone))
    end
  end

  it 'creates /24 networks relative to the VPC CIDR' do
    vpc_cidr = NetAddr::CIDR.create(variables.vpc_cidr)
    subnets.each do |subnet|
      subnet_cidr = NetAddr::CIDR.create(subnet.cidr_block)
      expect(subnet_cidr.netmask).to(eq('/24'))
      expect(vpc_cidr.contains?(subnet_cidr)).to(be(true))
    end
  end
end
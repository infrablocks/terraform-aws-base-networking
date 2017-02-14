require 'spec_helper'

describe 'public subnets' do
  include_context :terraform

  let :created_vpc do
    vpc("vpc-#{variables.component}-#{variables.deployment_identifier}")
  end
  let :public_subnets do
    variables.availability_zones.split(',').map do |zone|
      subnet("public-subnet-#{variables.component}-#{variables.deployment_identifier}-#{zone}")
    end
  end
  let :public_route_table do
    route_table("public-routetable-#{variables.component}-#{variables.deployment_identifier}")
  end

  context 'subnets' do
    it 'has a Component tag on each subnet' do
      public_subnets.each do |subnet|
        expect(subnet).to(have_tag('Component').value(variables.component))
      end
    end

    it 'has a DeploymentIdentifier tag on each subnet' do
      public_subnets.each do |subnet|
        expect(subnet).to(have_tag('DeploymentIdentifier')
                              .value(variables.deployment_identifier))
      end
    end

    it 'has a Tier of public on each subnet' do
      public_subnets.each do |subnet|
        expect(subnet).to(have_tag('Tier').value('public'))
      end
    end

    it 'associates each subnet with the created VPC' do
      public_subnets.each do |subnet|
        expect(subnet.vpc_id)
            .to(eq(created_vpc.id))
      end
    end

    it 'distributes subnets across availability zones' do
      variables.availability_zones.split(',').map do |zone|
        expect(public_subnets.map(&:availability_zone)).to(include(zone))
      end
    end

    it 'uses unique /24 networks relative to the VPC CIDR for each subnet' do
      vpc_cidr = NetAddr::CIDR.create(variables.vpc_cidr)

      public_subnets.each do |subnet|
        subnet_cidr = NetAddr::CIDR.create(subnet.cidr_block)

        expect(subnet_cidr.netmask).to(eq('/24'))
        expect(vpc_cidr.contains?(subnet_cidr)).to(be(true))
      end

      expect(public_subnets.map(&:cidr_block).uniq.length).to(eq(public_subnets.length))
    end
  end

  context 'route table' do
    it 'has a Component tag' do
      expect(public_route_table).to(have_tag('Component').value(variables.component))
    end

    it 'has a DeploymentIdentifier' do
      expect(public_route_table).to(have_tag('DeploymentIdentifier')
          .value(variables.deployment_identifier))
    end

    it 'has a Tier of public' do
      expect(public_route_table).to(have_tag('Tier').value('public'))
    end

    it 'is associated to the created VPC' do
      expect(public_route_table.vpc_id).to(eq(created_vpc.id))
    end

    it 'has a route to the internet gateway for all internet traffic' do
      internet_gateway =
          igw("igw-#{variables.component}-#{variables.deployment_identifier}")
      expect(public_route_table)
          .to(have_route('0.0.0.0/0').target(gateway: internet_gateway.id))
    end

    it 'is associated to each subnet' do
      public_subnets.each do |subnet|
        expect(public_route_table).to(have_subnet(subnet.id))
      end
    end
  end
end

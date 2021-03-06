require 'spec_helper'
require 'netaddr'

describe 'Public' do
  let(:component) { vars.component }
  let(:dep_id) { vars.deployment_identifier }

  let(:vpc_cidr) { vars.vpc_cidr }
  let(:availability_zones) { vars.availability_zones }

  let :created_vpc do
    vpc("vpc-#{component}-#{dep_id}")
  end
  let :public_subnets do
    availability_zones.map do |zone|
      subnet("public-subnet-#{component}-#{dep_id}-#{zone}")
    end
  end
  let :public_route_tables do
    availability_zones.map do |zone|
      route_table("public-routetable-#{component}-#{dep_id}-#{zone}")
    end
  end

  context 'subnets' do
    it 'has a Component tag on each subnet' do
      public_subnets.each do |subnet|
        expect(subnet).to(have_tag('Component').value(component))
      end
    end

    it 'has a DeploymentIdentifier tag on each subnet' do
      public_subnets.each do |subnet|
        expect(subnet).to(have_tag('DeploymentIdentifier')
            .value(dep_id))
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
      availability_zones.map do |zone|
        expect(public_subnets.map(&:availability_zone)).to(include(zone))
      end
    end

    it 'uses unique /24 networks relative to the VPC CIDR for each subnet' do
      cidr = NetAddr::IPv4Net.parse(vpc_cidr)

      public_subnets.each do |subnet|
        subnet_cidr = NetAddr::IPv4Net.parse(subnet.cidr_block)

        expect(subnet_cidr.netmask.cmp(NetAddr::Mask32.parse('/24'))).to(eq(0))
        expect(cidr.rel(subnet_cidr)).to(eq(1))
      end

      expect(public_subnets.map(&:cidr_block).uniq.length)
          .to(eq(public_subnets.length))
    end

    it 'exposes the public subnet IDs as an output' do
      expected_public_subnet_ids = public_subnets.map(&:id)
      actual_public_subnet_ids =
          output_for(:harness, 'public_subnet_ids')

      expect(actual_public_subnet_ids).to(eq(expected_public_subnet_ids))
    end

    it 'exposes the public subnet CIDR blocks as an output' do
      expected_public_subnet_ids = public_subnets.map(&:cidr_block)
      actual_public_subnet_ids =
          output_for(
              :harness, 'public_subnet_cidr_blocks')

      expect(actual_public_subnet_ids).to(eq(expected_public_subnet_ids))
    end
  end

  context 'route tables' do
    it 'has a Component tag on each route table' do
      public_route_tables.each do |route_table|
        expect(route_table).to(have_tag('Component').value(component))
      end
    end

    it 'has a DeploymentIdentifier on each route table' do
      public_route_tables.each do |route_table|
        expect(route_table).to(have_tag('DeploymentIdentifier')
            .value(dep_id))
      end
    end

    it 'has a Tier of public on each route table' do
      public_route_tables.each do |route_table|
        expect(route_table).to(have_tag('Tier')
            .value('public'))
      end
    end

    it 'associates each route table to the created VPC' do
      public_route_tables.each do |route_table|
        expect(route_table.vpc_id).to(eq(created_vpc.id))
      end
    end

    it 'has a route to the internet gateway for all internet traffic' do
      internet_gateway =
          igw("igw-#{component}-#{dep_id}")
      public_route_tables.each do |route_table|
        expect(route_table)
            .to(have_route('0.0.0.0/0').target(gateway: internet_gateway.id))
      end
    end

    it 'associates each route table to each subnet' do
      public_route_tables.zip(public_subnets)
          .each do |route_table, subnet|
        expect(route_table).to(have_subnet(subnet.id))
      end
    end

    it 'exposes the public route tables as an output' do
      expect(output_for(
          :harness, 'public_route_table_ids'))
          .to(eq(public_route_tables.map(&:id)))
    end
  end
end

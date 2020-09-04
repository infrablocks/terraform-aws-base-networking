require 'spec_helper'
require 'netaddr'

describe 'Private' do
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
  let :private_subnets do
    availability_zones.map do |zone|
      subnet("private-subnet-#{component}-#{dep_id}-#{zone}")
    end
  end
  let :private_route_tables do
    availability_zones.map do |zone|
      route_table("private-routetable-#{component}-#{dep_id}-#{zone}")
    end
  end
  let :nat_gateways do
    public_subnets.map do |subnet|
      ec2_client
          .describe_nat_gateways({
              filter: [
                  {name: 'vpc-id', values: [created_vpc.id]},
                  {name: 'subnet-id', values: [subnet.id]},
                  {name: 'state', values: ['available']}
              ]
          })
          .nat_gateways
          .single_resource(subnet.id)
    end
  end

  context 'subnets' do
    it 'has a Component tag on each subnet' do
      private_subnets.each do |subnet|
        expect(subnet).to(have_tag('Component').value(component))
      end
    end

    it 'has a DeploymentIdentifier tag on each subnet' do
      private_subnets.each do |subnet|
        expect(subnet).to(have_tag('DeploymentIdentifier')
            .value(dep_id))
      end
    end

    it 'has a Tier of private on each subnet' do
      private_subnets.each do |subnet|
        expect(subnet).to(have_tag('Tier').value('private'))
      end
    end

    it 'associates each subnet with the created VPC' do
      private_subnets.each do |subnet|
        expect(subnet.vpc_id)
            .to(eq(created_vpc.id))
      end
    end

    it 'distributes subnets across availability zones' do
      availability_zones.map do |zone|
        expect(private_subnets.map(&:availability_zone)).to(include(zone))
      end
    end

    it 'uses unique /24 networks relative to the VPC CIDR for each subnet' do
      cidr = NetAddr::IPv4Net.parse(vpc_cidr)

      private_subnets.each do |subnet|
        subnet_cidr = NetAddr::IPv4Net.parse(subnet.cidr_block)

        expect(subnet_cidr.netmask.cmp(NetAddr::Mask32.parse('/24'))).to(eq(0))
        expect(cidr.rel(subnet_cidr)).to(eq(1))
      end

      expect(private_subnets.map(&:cidr_block).uniq.length)
          .to(eq(private_subnets.length))
    end

    it 'exposes the private subnet IDs as an output' do
      expected_private_subnet_ids = private_subnets.map(&:id)
      actual_private_subnet_ids =
          output_for(
              :harness, 'private_subnet_ids', parse: true)

      expect(actual_private_subnet_ids).to(eq(expected_private_subnet_ids))
    end

    it 'exposes the private subnet CIDR blocks as an output' do
      expected_private_subnet_ids = private_subnets.map(&:cidr_block)
      actual_private_subnet_ids =
          output_for(
              :harness, 'private_subnet_cidr_blocks', parse: true)

      expect(actual_private_subnet_ids).to(eq(expected_private_subnet_ids))
    end
  end

  context 'route tables' do
    it 'has a Component tag on each route table' do
      private_route_tables.each do |route_table|
        expect(route_table).to(have_tag('Component').value(component))
      end
    end

    it 'has a DeploymentIdentifier on each route table' do
      private_route_tables.each do |route_table|
        expect(route_table)
            .to(have_tag('DeploymentIdentifier').value(dep_id))
      end
    end

    it 'has a Tier of private on each route table' do
      private_route_tables.each do |route_table|
        expect(route_table)
            .to(have_tag('Tier').value('private'))
      end
    end

    it 'associates each route table to the created VPC' do
      private_route_tables.each do |route_table|
        expect(route_table.vpc_id).to(eq(created_vpc.id))
      end
    end

    it 'includes a route to the NAT gateway for all internet traffic' do
      private_route_tables.zip(nat_gateways).each do |route_table, nat_gateway|
        expect(route_table)
            .to(have_route('0.0.0.0/0')
                .target(gateway: nat_gateway.nat_gateway_id))
      end
    end

    it 'associates each route table to each subnet' do
      private_route_tables.zip(private_subnets).each do |route_table, subnet|
        expect(route_table).to(have_subnet(subnet.id))
      end
    end

    it 'exposes the private route table ids as an output' do
      expect(output_for(
          :harness, 'private_route_table_ids', parse: true))
          .to(eq(private_route_tables.map(&:id)))
    end
  end
end

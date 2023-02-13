# frozen_string_literal: true

require 'spec_helper'
require 'netaddr'

# rubocop:disable RSpec/MultipleMemoizedHelpers
describe 'full example' do
  let(:component) do
    var(role: :full, name: 'component')
  end
  let(:dep_id) do
    var(role: :full, name: 'deployment_identifier')
  end
  let(:domain_name) do
    var(role: :full, name: 'domain_name')
  end
  let(:availability_zones) do
    var(role: :full, name: 'availability_zones')
  end
  let(:vpc_cidr) do
    var(role: :full, name: 'vpc_cidr')
  end
  let(:dependencies) do
    %w[other_vpc_1 other_vpc_2]
  end
  let(:dependencies_string) do
    'other_vpc_1,other_vpc_2'
  end

  before(:context) do
    apply(role: :full)
  end

  after(:context) do
    destroy(
      role: :full,
      only_if: -> { !ENV['FORCE_DESTROY'].nil? || ENV['SEED'].nil? }
    )
  end

  describe 'VPC' do
    subject(:created_vpc) { vpc("vpc-#{component}-#{dep_id}") }

    it { is_expected.to(exist) }

    it { is_expected.to(have_tag('Component').value(component)) }
    it { is_expected.to(have_tag('DeploymentIdentifier').value(dep_id)) }
    it { is_expected.to(have_tag('Dependencies').value(dependencies_string)) }

    its(:cidr_block) { is_expected.to(eq(vpc_cidr)) }

    it 'exposes the VPC ID as an output' do
      expected_vpc_id = created_vpc.vpc_id
      actual_vpc_id = output(role: :full, name: 'vpc_id')

      expect(actual_vpc_id).to(eq(expected_vpc_id))
    end

    it 'exposes the VPC CIDR block as an output' do
      expected_vpc_cidr = created_vpc.cidr_block
      actual_vpc_cidr = output(role: :full, name: 'vpc_cidr')

      expect(actual_vpc_cidr).to(eq(expected_vpc_cidr))
    end

    it 'enables DNS hostnames' do
      full_resource = Aws::EC2::Vpc.new(created_vpc.id)
      dns_hostnames =
        full_resource.describe_attribute({ attribute: 'enableDnsHostnames' })

      expect(dns_hostnames.enable_dns_hostnames.value).to be(true)
    end

    it 'exposes the availability zones as an output' do
      expected_availability_zones = availability_zones
      actual_availability_zones =
        output(role: :full, name: 'availability_zones')

      expect(actual_availability_zones).to(eq(expected_availability_zones))
    end

    it 'exposes the number of availability zones as an output' do
      expected_count = availability_zones.count
      actual_count =
        output(role: :full, name: 'number_of_availability_zones')

      expect(actual_count).to(eq(expected_count))
    end

    it 'associates the supplied private hosted with the VPC' do
      private_zone_id = output(role: :full, name: 'private_zone_id')
      private_hosted_zone =
        route53_client.get_hosted_zone({ id: private_zone_id })

      expect(private_hosted_zone.vp_cs.map(&:vpc_id))
        .to(include(created_vpc.id))
    end
  end

  describe 'IGW' do
    subject(:created_igw) do
      internet_gateway("igw-#{component}-#{dep_id}")
    end

    it { is_expected.to exist }
    it { is_expected.to have_tag('Component').value(component) }
    it { is_expected.to have_tag('DeploymentIdentifier').value(dep_id) }
    it { is_expected.to have_tag('Tier').value('public') }

    it 'is attached to the created VPC' do
      vpc_igw = vpc("vpc-#{component}-#{dep_id}")
                .internet_gateways.first

      expect(created_igw.internet_gateway_id)
        .to(eq(vpc_igw.internet_gateway_id))
    end
  end

  describe 'NAT gateways' do
    let :created_vpc do
      vpc("vpc-#{component}-#{dep_id}")
    end
    let :public_subnets do
      availability_zones.map do |zone|
        subnet("public-subnet-#{component}-#{dep_id}-#{zone}")
      end
    end

    let :nat_gateways do
      public_subnets.map do |subnet|
        ec2_client
          .describe_nat_gateways(
            {
              filter: [
                { name: 'vpc-id',
                  values: [created_vpc.id] },
                { name: 'subnet-id',
                  values: [subnet.id] },
                { name: 'state', values: ['available'] }
              ]
            }
          )
          .nat_gateways
          .first
      end.compact
    end

    it 'creates a NAT gateway in each public subnet' do
      expect(nat_gateways.length).to(eq(availability_zones.length))
    end

    it 'associates an EIP to each NAT gateway and exposes as an output' do
      nat_gateways.zip(output(role: :full, name: 'nat_public_ips'))
                  .each do |nat_gateway, nat_public_ip_output|
        expect(nat_gateway.nat_gateway_addresses.map(&:public_ip))
          .to(include(nat_public_ip_output))
      end
    end
  end

  describe 'private' do
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
          .describe_nat_gateways(
            {
              filter: [
                { name: 'vpc-id',
                  values: [created_vpc.id] },
                { name: 'subnet-id',
                  values: [subnet.id] },
                { name: 'state', values: ['available'] }
              ]
            }
          )
          .nat_gateways
          .single_resource(subnet.id)
      end
    end

    describe 'subnets' do
      it 'has a Component tag on each subnet' do
        expect(private_subnets)
          .to(all(have_tag('Component').value(component)))
      end

      it 'has a DeploymentIdentifier tag on each subnet' do
        expect(private_subnets)
          .to(all(have_tag('DeploymentIdentifier').value(dep_id)))
      end

      it 'has a Tier of private on each subnet' do
        expect(private_subnets)
          .to(all(have_tag('Tier').value('private')))
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

      # rubocop:disable RSpec/MultipleExpectations
      it 'uses unique /24 networks relative to the VPC CIDR for each subnet' do
        cidr = NetAddr::IPv4Net.parse(vpc_cidr)

        private_subnets.each do |subnet|
          subnet_cidr = NetAddr::IPv4Net.parse(subnet.cidr_block)

          expect(subnet_cidr.netmask.cmp(NetAddr::Mask32.parse('/24')))
            .to(eq(0))
          expect(cidr.rel(subnet_cidr)).to(eq(1))
        end

        expect(private_subnets.map(&:cidr_block).uniq.length)
          .to(eq(private_subnets.length))
      end
      # rubocop:enable RSpec/MultipleExpectations

      it 'exposes the private subnet IDs as an output' do
        expected_private_subnet_ids = private_subnets.map(&:id)
        actual_private_subnet_ids =
          output(role: :full, name: 'private_subnet_ids')

        expect(actual_private_subnet_ids).to(eq(expected_private_subnet_ids))
      end

      it 'exposes the private subnet CIDR blocks as an output' do
        expected_private_subnet_ids = private_subnets.map(&:cidr_block)
        actual_private_subnet_ids =
          output(role: :full, name: 'private_subnet_cidr_blocks')

        expect(actual_private_subnet_ids).to(eq(expected_private_subnet_ids))
      end
    end

    describe 'route tables' do
      it 'has a Component tag on each route table' do
        expect(private_route_tables)
          .to(all(have_tag('Component').value(component)))
      end

      it 'has a DeploymentIdentifier on each route table' do
        expect(private_route_tables)
          .to(all(have_tag('DeploymentIdentifier').value(dep_id)))
      end

      it 'has a Tier of private on each route table' do
        expect(private_route_tables)
          .to(all(have_tag('Tier').value('private')))
      end

      it 'associates each route table to the created VPC' do
        private_route_tables.each do |route_table|
          expect(route_table.vpc_id).to(eq(created_vpc.id))
        end
      end

      it 'includes a route to the NAT gateway for all internet traffic' do
        private_route_tables
          .zip(nat_gateways)
          .each do |route_table, nat_gateway|
          expect(route_table)
            .to(have_route('0.0.0.0/0')
                  .target(nat: nat_gateway.nat_gateway_id))
        end
      end

      it 'associates each route table to each subnet' do
        private_route_tables
          .zip(private_subnets)
          .each do |route_table, subnet|
          expect(route_table).to(have_subnet(subnet.id))
        end
      end

      it 'exposes the private route table ids as an output' do
        expect(output(role: :full, name: 'private_route_table_ids'))
          .to(eq(private_route_tables.map(&:id)))
      end
    end
  end

  describe 'public' do
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

    describe 'subnets' do
      it 'has a Component tag on each subnet' do
        expect(public_subnets)
          .to(all(have_tag('Component').value(component)))
      end

      it 'has a DeploymentIdentifier tag on each subnet' do
        expect(public_subnets)
          .to(all(have_tag('DeploymentIdentifier').value(dep_id)))
      end

      it 'has a Tier of public on each subnet' do
        expect(public_subnets)
          .to(all(have_tag('Tier').value('public')))
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

      # rubocop:disable RSpec/MultipleExpectations
      it 'uses unique /24 networks relative to the VPC CIDR for each subnet' do
        cidr = NetAddr::IPv4Net.parse(vpc_cidr)

        public_subnets.each do |subnet|
          subnet_cidr = NetAddr::IPv4Net.parse(subnet.cidr_block)

          expect(subnet_cidr.netmask.cmp(NetAddr::Mask32.parse('/24')))
            .to(eq(0))
          expect(cidr.rel(subnet_cidr)).to(eq(1))
        end

        expect(public_subnets.map(&:cidr_block).uniq.length)
          .to(eq(public_subnets.length))
      end
      # rubocop:enable RSpec/MultipleExpectations

      it 'exposes the public subnet IDs as an output' do
        expected_public_subnet_ids = public_subnets.map(&:id)
        actual_public_subnet_ids =
          output(role: :full, name: 'public_subnet_ids')

        expect(actual_public_subnet_ids).to(eq(expected_public_subnet_ids))
      end

      it 'exposes the public subnet CIDR blocks as an output' do
        expected_public_subnet_ids = public_subnets.map(&:cidr_block)
        actual_public_subnet_ids =
          output(role: :full, name: 'public_subnet_cidr_blocks')

        expect(actual_public_subnet_ids).to(eq(expected_public_subnet_ids))
      end
    end

    describe 'route tables' do
      it 'has a Component tag on each route table' do
        expect(public_route_tables)
          .to(all(have_tag('Component').value(component)))
      end

      it 'has a DeploymentIdentifier on each route table' do
        expect(public_route_tables)
          .to(all(have_tag('DeploymentIdentifier')
                    .value(dep_id)))
      end

      it 'has a Tier of public on each route table' do
        expect(public_route_tables)
          .to(all(have_tag('Tier').value('public')))
      end

      it 'associates each route table to the created VPC' do
        public_route_tables.each do |route_table|
          expect(route_table.vpc_id).to(eq(created_vpc.id))
        end
      end

      it 'has a route to the internet gateway for all internet traffic' do
        created_igw = internet_gateway("igw-#{component}-#{dep_id}")
        expect(public_route_tables)
          .to(all(have_route('0.0.0.0/0')
                    .target(gateway: created_igw.id)))
      end

      it 'associates each route table to each subnet' do
        public_route_tables
          .zip(public_subnets)
          .each do |route_table, subnet|
          expect(route_table).to(have_subnet(subnet.id))
        end
      end

      it 'exposes the public route tables as an output' do
        expect(output(role: :full, name: 'public_route_table_ids'))
          .to(eq(public_route_tables.map(&:id)))
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers

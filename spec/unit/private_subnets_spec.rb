# frozen_string_literal: true

require 'spec_helper'
require 'netaddr'

describe 'private' do
  let(:component) do
    var(role: :root, name: 'component')
  end
  let(:deployment_identifier) do
    var(role: :root, name: 'deployment_identifier')
  end
  let(:vpc_cidr) do
    var(role: :root, name: 'vpc_cidr')
  end
  let(:availability_zones) do
    var(role: :root, name: 'availability_zones')
  end

  describe 'subnets' do
    describe 'by default' do
      before(:context) do
        @plan = plan(role: :root) do |vars|
          vars.private_zone_id =
            output(role: :prerequisites, name: 'private_zone_id')
        end
      end

      it 'creates a subnet for each availability zone' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_subnet', name: 'private')
                .exactly(availability_zones.count).times)
      end

      it 'adds Component and DeploymentIdentifier tags on each subnet' do
        availability_zones.each do |availability_zone|
          expect(@plan)
            .to(include_resource_creation(type: 'aws_subnet', name: 'private')
                  .with_attribute_value(:availability_zone, availability_zone)
                  .with_attribute_value(
                    :tags,
                    a_hash_including(
                      Component: component,
                      DeploymentIdentifier: deployment_identifier
                    )
                  ))
        end
      end

      it 'adds a Tier tag of private on each subnet' do
        availability_zones.each do |availability_zone|
          expect(@plan)
            .to(include_resource_creation(type: 'aws_subnet', name: 'private')
                  .with_attribute_value(:availability_zone, availability_zone)
                  .with_attribute_value(
                    :tags,
                    a_hash_including(
                      Tier: 'private'
                    )
                  ))
        end
      end

      it 'uses /24 networks relative to the VPC CIDR for each subnet' do
        availability_zones.each do |availability_zone|
          expect(@plan)
            .to(include_resource_creation(type: 'aws_subnet', name: 'private')
                  .with_attribute_value(:availability_zone, availability_zone)
                  .with_attribute_value(
                    :cidr_block,
                    a_cidr_block_within(vpc_cidr).of_size('/24')
                  ))
        end
      end

      it 'uses unique CIDRs for each subnet' do
        private_subnet_creations =
          @plan.resource_changes_matching(type: 'aws_subnet', name: 'private')
        cidr_blocks = private_subnet_creations.map do |creation|
          creation.change.after_object[:cidr_block]
        end

        expect(cidr_blocks.uniq.length).to(eq(availability_zones.length))
      end

      it 'outputs the private subnet IDs' do
        expect(@plan)
          .to(include_output_creation(name: 'private_subnet_ids'))
      end

      it 'outputs the private subnet CIDR blocks' do
        expect(@plan)
          .to(include_output_creation(name: 'private_subnet_cidr_blocks'))
      end
    end
  end

  describe 'route tables' do
    describe 'by default' do
      before(:context) do
        @plan = plan(role: :root) do |vars|
          vars.private_zone_id =
            output(role: :prerequisites, name: 'private_zone_id')
        end
      end

      it 'creates a route table for each availability zone' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_route_table',
                                        name: 'private')
                .exactly(availability_zones.count).times)
      end

      it 'adds Component and DeploymentIdentifier tags on each route table' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_route_table',
            name: 'private'
          )
                .with_attribute_value(
                  :tags,
                  a_hash_including(
                    Component: component,
                    DeploymentIdentifier: deployment_identifier
                  )
                )
                .exactly(availability_zones.length).times)
      end

      it 'adds a Tier tag of private on each route table' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_route_table',
            name: 'private'
          )
                .with_attribute_value(
                  :tags,
                  a_hash_including(
                    Tier: 'private'
                  )
                ).exactly(availability_zones.length).times)
      end

      it 'creates a catch all route for each route table' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_route', name: 'private_internet'
          )
                .with_attribute_value(:destination_cidr_block, '0.0.0.0/0')
                .exactly(availability_zones.length).times)
      end

      it 'creates a route table association for each route table' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_route_table_association',
            name: 'private'
          )
                .exactly(availability_zones.length).times)
      end

      it 'outputs the private route table IDs' do
        expect(@plan)
          .to(include_output_creation(name: 'private_route_table_ids'))
      end
    end

    describe 'when include_nat_gateways is "no"' do
      before(:context) do
        @plan = plan(role: :root) do |vars|
          vars.include_nat_gateways = 'no'
          vars.private_zone_id =
            output(role: :prerequisites, name: 'private_zone_id')
        end
      end

      it 'creates a route table for each availability zone' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_route_table',
                                        name: 'private')
                .exactly(availability_zones.count).times)
      end

      it 'creates a route table association for each route table' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_route_table_association',
            name: 'private'
          )
                .exactly(availability_zones.length).times)
      end

      it 'does not create any routes in each route table' do
        expect(@plan)
          .not_to(include_resource_creation(
                    type: 'aws_route', name: 'private_internet'
                  ))
      end
    end

    describe 'when include_nat_gateways is "yes"' do
      before(:context) do
        @plan = plan(role: :root) do |vars|
          vars.include_nat_gateways = 'yes'
          vars.private_zone_id =
            output(role: :prerequisites, name: 'private_zone_id')
        end
      end

      it 'creates a route table for each availability zone' do
        expect(@plan)
          .to(include_resource_creation(type: 'aws_route_table',
                                        name: 'private')
                .exactly(availability_zones.count).times)
      end

      it 'creates a route table association for each route table' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_route_table_association',
            name: 'private'
          )
                .exactly(availability_zones.length).times)
      end

      it 'creates a catch all route for each route table' do
        expect(@plan)
          .to(include_resource_creation(
            type: 'aws_route', name: 'private_internet'
          )
                .with_attribute_value(:destination_cidr_block, '0.0.0.0/0')
                .exactly(availability_zones.length).times)
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

describe 'NAT gateways' do
  let(:component) do
    var(role: :root, name: 'component')
  end
  let(:deployment_identifier) do
    var(role: :root, name: 'deployment_identifier')
  end
  let(:availability_zones) do
    var(role: :root, name: 'availability_zones').keys
  end

  describe 'by default' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.private_zone_id =
          output(role: :prerequisites, name: 'private_zone_id')
      end
    end

    it 'creates a NAT gateway in each public subnet' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_nat_gateway')
              .exactly(availability_zones.count).times)
    end

    it 'includes a Name tag on each NAT gateway' do
      availability_zones.each do |availability_zone|
        name = "nat-#{component}-#{deployment_identifier}-#{availability_zone}"
        expect(@plan)
          .to(include_resource_creation(type: 'aws_nat_gateway')
                .with_attribute_value(:tags, a_hash_including(Name: name)))
      end
    end

    it 'includes Component and DeploymentIdentifier tags on each NAT gateway' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_nat_gateway')
              .with_attribute_value(
                :tags,
                a_hash_including(
                  Component: component,
                  DeploymentIdentifier: deployment_identifier
                )
              )
              .exactly(availability_zones.count).times)
    end

    it 'creates an EIP for each public subnet' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_eip')
              .exactly(availability_zones.count).times)
    end

    it 'includes a Name tag on each EIP' do
      availability_zones.each do |availability_zone|
        name =
          "eip-nat-#{component}-#{deployment_identifier}-#{availability_zone}"
        expect(@plan)
          .to(include_resource_creation(type: 'aws_eip')
                .with_attribute_value(:tags, a_hash_including(Name: name)))
      end
    end

    it 'includes Component and DeploymentIdentifier tags on each EIP' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_eip')
              .with_attribute_value(
                :tags,
                a_hash_including(
                  Component: component,
                  DeploymentIdentifier: deployment_identifier
                )
              )
              .exactly(availability_zones.count).times)
    end

    it 'outputs the NAT public IPs' do
      expect(@plan)
        .to(include_output_creation(name: 'nat_public_ips'))
    end
  end

  context 'when include_nat_gateways is no' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.include_nat_gateways = 'no'
        vars.private_zone_id =
          output(role: :prerequisites, name: 'private_zone_id')
      end
    end

    it 'does not create any NAT gateways' do
      expect(@plan)
        .not_to(include_resource_creation(type: 'aws_nat_gateway'))
    end

    it 'does not create any EIPs' do
      expect(@plan)
        .not_to(include_resource_creation(type: 'aws_eip'))
    end
  end

  context 'when include_nat_gateways is yes' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.include_nat_gateways = 'yes'
        vars.private_zone_id =
          output(role: :prerequisites, name: 'private_zone_id')
      end
    end

    it 'creates a NAT gateway in each public subnet' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_nat_gateway')
              .exactly(availability_zones.count).times)
    end

    it 'includes a Name tag on each NAT gateway' do
      availability_zones.each do |availability_zone|
        name = "nat-#{component}-#{deployment_identifier}-#{availability_zone}"
        expect(@plan)
          .to(include_resource_creation(type: 'aws_nat_gateway')
                .with_attribute_value(:tags, a_hash_including(Name: name)))
      end
    end

    it 'includes Component and DeploymentIdentifier tags on each NAT gateway' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_nat_gateway')
              .with_attribute_value(
                :tags,
                a_hash_including(
                  Component: component,
                  DeploymentIdentifier: deployment_identifier
                )
              )
              .exactly(availability_zones.count).times)
    end

    it 'creates an EIP for each public subnet' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_eip')
              .exactly(availability_zones.count).times)
    end

    it 'includes a Name tag on each EIP' do
      availability_zones.each do |availability_zone|
        name =
          "eip-nat-#{component}-#{deployment_identifier}-#{availability_zone}"
        expect(@plan)
          .to(include_resource_creation(type: 'aws_eip')
                .with_attribute_value(:tags, a_hash_including(Name: name)))
      end
    end

    it 'includes Component and DeploymentIdentifier tags on each EIP' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_eip')
              .with_attribute_value(
                :tags,
                a_hash_including(
                  Component: component,
                  DeploymentIdentifier: deployment_identifier
                )
              )
              .exactly(availability_zones.count).times)
    end
  end
end

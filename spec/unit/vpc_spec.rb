# frozen_string_literal: true

require 'spec_helper'

describe 'VPC' do
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
  let(:private_zone_id) do
    output(role: :prerequisites, name: 'private_zone_id')
  end

  describe 'by default' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.private_zone_id =
          output(role: :prerequisites, name: 'private_zone_id')
      end
    end

    it 'creates a VPC' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_vpc')
              .once)
    end

    it 'uses the provided VPC CIDR' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_vpc')
              .with_attribute_value(:cidr_block, vpc_cidr))
    end

    it 'uses enables DNS hostnames' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_vpc')
              .with_attribute_value(
                :enable_dns_hostnames, true
              ))
    end

    it 'includes Component and DeploymentIdentifier tags' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_vpc')
              .with_attribute_value(
                :tags,
                a_hash_including(
                  Component: component,
                  DeploymentIdentifier: deployment_identifier
                )
              ))
    end

    it 'includes a Dependencies tag as an empty string' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_vpc')
              .with_attribute_value(
                :tags,
                a_hash_including(Dependencies: '')
              ))
    end

    it 'outputs the VPC ID' do
      expect(@plan)
        .to(include_output_creation(name: 'vpc_id'))
    end

    it 'outputs the VPC CIDR' do
      expect(@plan)
        .to(include_output_creation(name: 'vpc_cidr')
              .with_value(vpc_cidr))
    end

    it 'outputs the availability zones' do
      expect(@plan)
        .to(include_output_creation(name: 'availability_zones')
              .with_value(availability_zones))
    end

    it 'outputs the number of availability zones' do
      expect(@plan)
        .to(include_output_creation(name: 'number_of_availability_zones')
              .with_value(availability_zones.length))
    end

    it 'creates a Route 53 zone association for the provided ' \
       'hosted zone' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_route53_zone_association')
              .with_attribute_value(:zone_id, private_zone_id))
    end
  end

  context 'when include_route53_zone_association is "no"' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.include_route53_zone_association = 'no'
      end
    end

    it 'does not create a Route53 zone association' do
      expect(@plan)
        .not_to(include_resource_creation(type: 'aws_route53_zone_association'))
    end
  end

  context 'when include_route53_zone_association is "yes"' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.include_route53_zone_association = 'yes'
        vars.private_zone_id =
          output(role: :prerequisites, name: 'private_zone_id')
      end
    end

    it 'creates a Route 53 zone association for the provided ' \
       'hosted zone' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_route53_zone_association')
              .with_attribute_value(:zone_id, private_zone_id))
    end
  end

  context 'when dependencies are provided' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.dependencies = %w[first second]
        vars.private_zone_id =
          output(role: :prerequisites, name: 'private_zone_id')
      end
    end

    it 'includes a Dependencies tag containing the dependencies' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_vpc')
              .with_attribute_value(
                :tags,
                a_hash_including(Dependencies: 'first,second')
              ))
    end
  end
end

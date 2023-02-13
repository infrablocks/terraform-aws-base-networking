# frozen_string_literal: true

require 'spec_helper'

describe 'IGW' do
  let(:component) do
    var(role: :root, name: 'component')
  end
  let(:deployment_identifier) do
    var(role: :root, name: 'deployment_identifier')
  end

  describe 'by default' do
    before(:context) do
      @plan = plan(role: :root) do |vars|
        vars.private_zone_id =
          output(role: :prerequisites, name: 'private_zone_id')
      end
    end

    it 'creates an internet gateway' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_internet_gateway')
              .once)
    end

    it 'includes a Name tag' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_internet_gateway')
              .with_attribute_value(
                :tags,
                a_hash_including(
                  Name: "igw-#{component}-#{deployment_identifier}"
                )
              ))
    end

    it 'includes Component and DeploymentIdentifier tags' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_internet_gateway')
              .with_attribute_value(
                :tags,
                a_hash_including(
                  Component: component,
                  DeploymentIdentifier: deployment_identifier
                )
              ))
    end

    it 'includes a Tier tag' do
      expect(@plan)
        .to(include_resource_creation(type: 'aws_internet_gateway')
              .with_attribute_value(
                :tags,
                a_hash_including(
                  Tier: 'public'
                )
              ))
    end
  end
end

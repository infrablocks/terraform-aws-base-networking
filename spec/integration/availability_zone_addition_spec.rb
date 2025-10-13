# frozen_string_literal: true

require 'spec_helper'
require 'json'

describe 'availability zone addition' do
  let(:initial_availability_zones) do
    %w[eu-west-1a eu-west-1b]
  end

  let(:updated_availability_zones) do
    %w[eu-west-1a eu-west-1b eu-west-1c]
  end

  let(:component) { 'test-component' }
  let(:deployment_identifier) { 'test-deployment' }
  let(:vpc_cidr) { '10.0.0.0/16' }
  let(:region) { 'eu-west-1' }

  describe 'adding a new availability zone' do
    let(:test_dir) { @test_dir }

    after do
      # Cleanup: destroy all resources created during the test
      if @test_dir && Dir.exist?(@test_dir)
        terraform_exec = from_root_directory('vendor/terraform/bin/terraform')
        Dir.chdir(@test_dir) do
          system("#{terraform_exec} destroy -auto-approve")
        end
      end
    end

    it 'does not destroy existing subnets when adding a new availability zone' do
      # Step 1: Apply with initial set of availability zones
      initial_state = apply_and_get_state(initial_availability_zones)

      # Get the initial subnet IDs
      initial_public_subnet_ids = get_resource_ids(initial_state, 'aws_subnet',
                                                   'public')
      initial_private_subnet_ids = get_resource_ids(initial_state,
                                                    'aws_subnet', 'private')
      initial_nat_gateway_ids = get_resource_ids(initial_state,
                                                 'aws_nat_gateway', 'base')
      initial_eip_ids = get_resource_ids(initial_state, 'aws_eip', 'nat')

      # Step 2: Plan with additional availability zone
      plan_output = plan_with_azs(updated_availability_zones)

      # Parse the plan output to check for destructions
      plan_json = JSON.parse(plan_output)

      # Check that no existing resources are being destroyed
      resource_changes = plan_json['resource_changes'] || []

      # Find any destroy actions for our existing resources
      destroyed_resources = resource_changes.select do |change|
        change['change']['actions'].include?('delete') &&
          (initial_public_subnet_ids.values.include?(change['change']['before']['id']) ||
           initial_private_subnet_ids.values.include?(change['change']['before']['id']) ||
           initial_nat_gateway_ids.values.include?(change['change']['before']['id']) ||
           initial_eip_ids.values.include?(change['change']['before']['id']))
      end

      # Assert no existing resources are being destroyed
      expect(destroyed_resources).to be_empty,
                                     "Expected no resources to be destroyed, but found: #{destroyed_resources.map do |r|
                                                                                            "#{r['type']}.#{r['name']}"
                                                                                          end.join(', ')}"

      # Check that only new resources are being created
      created_resources = resource_changes.select do |change|
        change['change']['actions'].include?('create') &&
          %w[aws_subnet aws_route_table aws_route_table_association aws_route
             aws_nat_gateway aws_eip].include?(change['type'])
      end

      # We expect exactly 1 new public subnet, 1 new private subnet,
      # 2 new route tables, 2 new route table associations,
      # 1 new NAT gateway, and 1 new EIP for the new AZ
      expected_new_resources = {
        'aws_subnet' => 2, # 1 public + 1 private
        'aws_route_table' => 2, # 1 for public + 1 for private
        'aws_route_table_association' => 2, # 1 for public + 1 for private
        'aws_route' => 2, # 1 for public internet route + 1 for private NAT route
        'aws_nat_gateway' => 1,
        'aws_eip' => 1
      }

      actual_new_resources = created_resources.group_by { |r| r['type'] }
                                              .transform_values(&:count)

      expected_new_resources.each do |resource_type, expected_count|
        actual_count = actual_new_resources[resource_type] || 0
        expect(actual_count).to eq(expected_count),
                                "Expected #{expected_count} new #{resource_type} resources, but found #{actual_count}"
      end
    end
  end

  private

  def apply_and_get_state(availability_zones)
    terraform_exec = from_root_directory('vendor/terraform/bin/terraform')
    # Create a temporary directory for this test run
    @test_dir = "spec/integration/test_runs/#{Time.now.to_i}"
    FileUtils.mkdir_p(@test_dir)

    # Write the terraform configuration
    File.write("#{@test_dir}/main.tf",
               generate_terraform_config(availability_zones))

    # Initialize and apply
    Dir.chdir(@test_dir) do
      init_result = system("#{terraform_exec} init")
      raise 'Terraform init failed' unless init_result

      apply_result = system("#{terraform_exec} apply -auto-approve")
      raise 'Terraform apply failed' unless apply_result

      # Get the state - properly write to file
      state_json = `#{terraform_exec} show -json`
      File.write('initialstate.json', state_json)
      JSON.parse(state_json)
    end
  end

  def plan_with_azs(availability_zones)
    # Update the configuration with new AZs
    test_dir = Dir.glob('spec/integration/test_runs/*').last
    File.write("#{test_dir}/main.tf",
               generate_terraform_config(availability_zones))

    terraform_exec = from_root_directory('vendor/terraform/bin/terraform')

    # Run plan and capture output
    Dir.chdir(test_dir) do
      `#{terraform_exec} plan -out=tfplan -json`
      `#{terraform_exec} show -json tfplan > tfplan.json`
      `cat tfplan.json`
    end
  end

  def generate_terraform_config(availability_zones)
    <<~HCL
      terraform {
        required_providers {
          aws = {
            source  = "hashicorp/aws"
            version = "~> 4.0"
          }
        }
      }

      provider "aws" {
        region = "#{region}"
      }

      module "base_networking" {
        source = "#{from_root_directory('')}"

        vpc_cidr                         = "#{vpc_cidr}"
        region                           = "#{region}"
        availability_zones               = #{availability_zones.inspect}
        component                        = "#{component}"
        deployment_identifier            = "#{deployment_identifier}"
        include_route53_zone_association = "no"
      }
    HCL
  end

  def from_root_directory(dir)
    "../../../../#{dir}"
  end

  def get_resource_ids(state, resource_type, resource_name)
    resources = state['values']['root_module']['child_modules']
                &.first&.[]('resources') || []

    resources.select do |r|
      r['type'] == resource_type && r['name'] == resource_name
    end.to_h do |r|
      # For for_each resources, use the index key (AZ name) as the key
      if r['index'].is_a?(String)
        [r['index'], r['values']['id']]
      else
        [r['index'].to_s, r['values']['id']]
      end
    end
  end
end

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
    # Step 1: Apply with initial set of availability zones
    let(:initial_state) { apply_and_get_state(initial_availability_zones) }
    # Step 2: Plan with additional availability zone
    let(:plan_output) { plan_with_azs(updated_availability_zones) }
    # Parse the plan output to check for destructions
    let(:plan_json) { JSON.parse(plan_output) }
    let(:resource_changes) { plan_json['resource_changes'] || [] }

    it 'does not destroy existing resources when adding a new az zone' do
      # Get the initial subnet IDs
      initial_public_subnet_ids = get_resource_ids(initial_state, 'aws_subnet',
                                                   'public')
      initial_private_subnet_ids = get_resource_ids(initial_state,
                                                    'aws_subnet', 'private')
      initial_nat_gateway_ids = get_resource_ids(initial_state,
                                                 'aws_nat_gateway', 'base')
      initial_eip_ids = get_resource_ids(initial_state, 'aws_eip', 'nat')

      # Find any destroy actions for our existing resources
      destroyed_resources = resource_changes.select do |change|
        change['change']['actions'].include?('delete') &&
          (initial_public_subnet_ids.values.include?(change['change']['before']['id']) ||
           initial_private_subnet_ids.values.include?(change['change']['before']['id']) ||
           initial_nat_gateway_ids.values.include?(change['change']['before']['id']) ||
           initial_eip_ids.values.include?(change['change']['before']['id']))
      end

      # Assert no existing resources are being destroyed
      destroyed_resource_str = destroyed_resources.map do |r|
        "#{r['type']}.#{r['name']}"
      end.join(', ')
      expect(destroyed_resources).to be_empty,
                                     'Expected no resources to be destroyed,' \
                                     "but found: #{destroyed_resource_str}"
    end

    it 'creates the expected new resources for the additional az zone' do
      # Check that only new resources are being created
      created_resources = resource_changes.select do |change|
        change['change']['actions'].include?('create') &&
          %w[aws_subnet aws_route_table aws_route_table_association
             aws_nat_gateway aws_eip].include?(change['type'])
      end

      # We expect exactly 1 new public subnet, 1 new private subnet,
      # 2 new route tables, 2 new route table associations,
      # 1 new NAT gateway, and 1 new EIP for the new AZ
      expected_new_resources = {
        'aws_subnet' => 2, # 1 public + 1 private
        'aws_route_table' => 2, # 1 for public + 1 for private
        'aws_route_table_association' => 2, # 1 for public + 1 for private
        'aws_route' => 2, # 1 for public internet route +1 for private NAT route
        'aws_nat_gateway' => 1,
        'aws_eip' => 1
      }

      actual_new_resources = created_resources.group_by { |r| r['type'] }
                                              .transform_values(&:count)

      expect(actual_new_resources).to eq(expected_new_resources)
    end
  end

  private

  def apply_and_get_state(availability_zones)
    # Create a temporary directory for this test run
    test_dir = "spec/integration/test_runs/#{Time.now.to_i}"
    FileUtils.mkdir_p(test_dir)

    # Write the terraform configuration
    File.write("#{test_dir}/main.tf",
               generate_terraform_config(availability_zones))

    # Initialize and apply
    Dir.chdir(test_dir) do
      terraform = terraform_exe('../../../../')

      system("#{terraform} init", out: File::NULL, err: File::NULL)
      system("#{terraform} apply -auto-approve", out: File::NULL, err: File::NULL)

      # Get the state
      state_output = `#{terraform} show -json`
      JSON.parse(state_output)
    end

    # Cleanup is handled by the test framework
  end

  def plan_with_azs(availability_zones)
    # Update the configuration with new AZs
    test_dir = Dir.glob('spec/integration/test_runs/*').last
    File.write("#{test_dir}/main.tf",
               generate_terraform_config(availability_zones))

    terraform = terraform_exe('../../../../')

    # Run plan and capture output
    Dir.chdir(test_dir) do
      `#{terraform} plan -out=tfplan -json`
      `#{terraform} show -json tfplan > tfplan.json`
      `cat tfplan.json`
    end
  end

  def terraform_exe(root_dir)
    "#{root_dir}vendor/terraform/bin/terraform"
  end

  def generate_terraform_config(availability_zones)
    <<~HCL
      module "base_networking" {
        source = "../../../../"

        vpc_cidr              = "#{vpc_cidr}"
        region                = "#{region}"
        availability_zones    = #{availability_zones.inspect}
        component             = "#{component}"
        deployment_identifier = "#{deployment_identifier}"
      }

      provider "aws" {
        region = "#{region}"
        version = "3.29"
      }
    HCL
  end

  def get_resource_ids(state, resource_type, resource_name)
    resources = state['values']['root_module']['child_modules']
                &.first&.[]('resources') || []

    matching_resources = resources.select do |r|
      r['type'] == resource_type && r['name'] == resource_name
    end

    matching_resources.to_h do |r|
      # For for_each resources, use the index key (AZ name) as the key
      index_key = r['index'].to_s
      [index_key, r['values']['id']]
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'
require 'json'

# TODO
# extract function for executing terraform

INITIAL_AVAILABILITY_ZONES = %w[eu-west-1a eu-west-1b].freeze
UPDATED_AVAILABILITY_ZONES = %w[eu-west-1a eu-west-1b eu-west-1c].freeze

COMPONENT = 'test-component'
DEPLOYMENT_IDENTIFIER = 'test-deployment'
VPC_CIDR = '10.0.0.0/16'
REGION = 'eu-west-1'

describe 'availability zone addition' do
  describe 'adding a new availability zone' do
    let(:initial_state) { @initial_state }
    let(:resource_changes) { @resource_changes }

    before(:all) do
      @test_dir = make_test_run_dir

      # Apply initial availability zones
      apply_availability_zones(@test_dir, INITIAL_AVAILABILITY_ZONES)
      Dir.chdir(@test_dir) do
        @initial_state = get_terraform_state('applied.json')
      end

      # Run plan with additional availability zone
      plan_output = plan_with_azs(@test_dir, UPDATED_AVAILABILITY_ZONES)
      plan_json = JSON.parse(plan_output)
      @resource_changes = plan_json['resource_changes'] || []
    end

    after(:all) do
      # Cleanup: destroy all resources created during the test
      if @test_dir && Dir.exist?(@test_dir)
        Dir.chdir(@test_dir) do
          terraform_exec = from_root_directory('vendor/terraform/bin/terraform')
          system("#{terraform_exec} destroy -auto-approve")
        end
      end
    end

    it 'does not destroy existing subnets when adding new availability zone' do
      # Get the initial subnet IDs
      resource_ids = gather_resource_ids(initial_state)

      # Find any destroy actions for our existing resources
      destroyed_resources = resource_changes.select do |change|
        before_id = change.dig('change', 'before', 'id')
        change['change']['actions'].include?('delete') &&
          (resource_ids['public_subnets'].values.include?(before_id) ||
            resource_ids['private_subnets'].values.include?(before_id) ||
            resource_ids['nat_gateways'].values.include?(before_id) ||
            resource_ids['eips'].values.include?(before_id))
      end

      # Assert no existing resources are being destroyed
      destroyed_resource_str = destroyed_resources.map do |r|
        "#{r['type']}.#{r['name']}"
      end.join(', ')
      expect(destroyed_resources).to(
        be_empty,
        'Expected no resources to be destroyed, ' \
        "but found: #{destroyed_resource_str}"
      )
    end

    it 'creates resources for new availability zone' do
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
        # 1 for public internet route + 1 for private NAT route
        'aws_route' => 2,
        'aws_nat_gateway' => 1,
        'aws_eip' => 1
      }

      actual_new_resources = created_resources.group_by { |r| r['type'] }
                                              .transform_values(&:count)

      expected_new_resources.each do |resource_type, expected_count|
        actual_count = actual_new_resources[resource_type] || 0
        expect(actual_count).to(
          eq(expected_count),
          "Expected #{expected_count} new #{resource_type} resources, " \
          "but found #{actual_count}"
        )
      end
    end
  end

  private

  def make_test_run_dir
    dir = "spec/integration/test_runs/#{Time.now.to_i}"
    FileUtils.mkdir_p(dir)
    dir
  end

  def apply_availability_zones(terraform_dir, availability_zones)
    terraform_exec = from_root_directory('vendor/terraform/bin/terraform')

    # Write the terraform configuration
    File.write("#{terraform_dir}/main.tf",
               generate_terraform_config(availability_zones))

    # Initialize and apply
    Dir.chdir(terraform_dir) do
      init_result = system("#{terraform_exec} init")
      raise 'Terraform init failed' unless init_result

      apply_result = system("#{terraform_exec} apply -auto-approve")
      raise 'Terraform apply failed' unless apply_result
    end
  end

  def get_terraform_state(state_file)
    terraform_exec = from_root_directory('vendor/terraform/bin/terraform')
    state_json = `#{terraform_exec} show -json`
    File.write(state_file, state_json)
    JSON.parse(state_json)
  end

  def plan_with_azs(terraform_dir, availability_zones)
    terraform_exec = from_root_directory('vendor/terraform/bin/terraform')
    # Update the configuration with new AZs
    File.write("#{terraform_dir}/main.tf",
               generate_terraform_config(availability_zones))

    # Run plan and capture output
    Dir.chdir(terraform_dir) do
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
        region = "#{REGION}"
      }

      module "base_networking" {
        source = "#{from_root_directory('')}"

        vpc_cidr                         = "#{VPC_CIDR}"
        region                           = "#{REGION}"
        availability_zones               = #{availability_zones.inspect}
        component                        = "#{COMPONENT}"
        deployment_identifier            = "#{DEPLOYMENT_IDENTIFIER}"
        include_route53_zone_association = "no"
      }
    HCL
  end

  def from_root_directory(dir)
    "../../../../#{dir}"
  end

  def gather_resource_ids(state)
    {
      public_subnets: get_resource_ids(state, 'aws_subnet', 'public'),
      private_subnets: get_resource_ids(state, 'aws_subnet', 'private'),
      nat_gateways: get_resource_ids(state, 'aws_nat_gateway', 'base'),
      eips: get_resource_ids(state, 'aws_eip', 'nat')
    }
  end

  def get_resource_ids(state, resource_type, resource_name)
    resources = state['values']['root_module']['child_modules']
                &.first&.[]('resources') || []

    matching_resources = resources.select do |r|
      r['type'] == resource_type && r['name'] == resource_name
    end

    matching_resources.to_h do |r|
      # For for_each resources, use the index key (AZ name) as the key
      [r['index'].to_s, r['values']['id']]
    end
  end
end

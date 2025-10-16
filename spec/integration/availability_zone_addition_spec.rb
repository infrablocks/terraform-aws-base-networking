# frozen_string_literal: true

require 'spec_helper'
require 'netaddr'

ORIGINAL_AVAILABILITY_ZONES = %w[eu-west-2a eu-west-2b].freeze
UPDATED_AVAILABILITY_ZONES = %w[eu-west-2a eu-west-2b eu-west-2c].freeze

describe 'adding additional availability zones' do
  let(:component) do
    var(role: :full, name: 'component')
  end
  let(:dep_id) do
    var(role: :full, name: 'deployment_identifier')
  end
  let(:domain_name) do
    var(role: :full, name: 'domain_name')
  end
  let(:vpc_cidr) do
    var(role: :full, name: 'vpc_cidr')
  end
  let(:private_subnets_offset) do
    var(role: :full, name: 'private_subnets_offset')
  end

  before(:context) do
    apply(role: :full) do |vars|
      vars.availability_zones = ORIGINAL_AVAILABILITY_ZONES
    end
  end

  after(:context) do
    destroy(
      role: :full,
      only_if: -> { !ENV['FORCE_DESTROY'].nil? || ENV['SEED'].nil? }
    )
  end

  it 'creates the initial availability zones' do
    expected_availability_zones = ORIGINAL_AVAILABILITY_ZONES
    actual_availability_zones = output(role: :full, name: 'availability_zones')
    expect(actual_availability_zones).to(eq(expected_availability_zones))
  end

  describe 'adding a new availability zone' do
    before(:context) do
      @plan = plan(role: :full) do |vars|
        vars.availability_zones = UPDATED_AVAILABILITY_ZONES
      end
    end

    def expect_addition_of_one_new_resource(state, type, name)
      expect(state)
        .not_to(include_resource_deletion(type:, name:))
      expect(state)
        .not_to(include_resource_update(type:, name:))
      expect(state)
        .not_to(include_resource_replacement(type:, name:))
      expect(state)
        .to(include_resource_creation(type:, name:)
              .exactly(1).times)
    end

    it 'adds a single new private subnet' do
      expect_addition_of_one_new_resource(@plan, 'aws_subnet', 'private')
    end

    it 'adds a single new public subnet' do
      expect_addition_of_one_new_resource(@plan, 'aws_subnet', 'public')
    end

    it 'adds a single new nat gateway' do
      expect_addition_of_one_new_resource(@plan, 'aws_nat_gateway', 'base')
    end

    it 'adds a single new eip' do
      expect_addition_of_one_new_resource(@plan, 'aws_eip', 'nat')
    end
  end
end

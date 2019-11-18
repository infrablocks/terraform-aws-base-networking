require 'awspec'
require 'ostruct'

require_relative '../awspec'
require_relative '../terraform_module'

shared_context :terraform do
  include Awspec::Helper::Finder

  let(:vars) {
    OpenStruct.new(
        TerraformModule.configuration
            .for(:harness)
            .vars)
  }

  def configuration
    TerraformModule.configuration
  end

  def output_for(role, name)
    TerraformModule.output_for(role, name)
  end

  def reprovision(overrides = nil)
    TerraformModule.provision_for(
        :harness,
        TerraformModule.configuration.for(:harness, overrides).vars)
  end
end
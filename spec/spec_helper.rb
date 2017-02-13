require 'bundler/setup'

require 'awspec'
require 'support/awspec'

require 'support/shared_contexts/terraform'

require_relative '../lib/terraform'

RSpec.configure do |config|
  config.example_status_persistence_file_path = '.rspec_status'

  config.add_setting :region, default: 'eu-west-2'
  config.add_setting :vpc_cidr, default: "10.1.0.0/16"
  config.add_setting :component, default: 'integration-tests'

  config.add_setting :deployment_identifier, default: SecureRandom.hex[0, 8]

  config.before(:suite) do
    variables = RSpec.configuration
    configuration_directory = Paths.from_project_root_directory('src')

    puts
    puts "Provisioning with deployment identifier: #{variables.deployment_identifier}"
    puts

    Terraform.clean
    Terraform.apply(directory: configuration_directory, vars: {
        region: variables.region,
        vpc_cidr: variables.vpc_cidr,
        component: variables.component,
        deployment_identifier: variables.deployment_identifier
    })

    puts
  end

  config.after(:suite) do
    variables = RSpec.configuration
    configuration_directory = Paths.from_project_root_directory('src')

    puts
    puts "Destroying with deployment identifier: #{variables.deployment_identifier}"
    puts

    Terraform.clean
    Terraform.destroy(directory: configuration_directory, vars: {
        region: variables.region,
        vpc_cidr: variables.vpc_cidr,
        component: variables.component,
        deployment_identifier: variables.deployment_identifier
    })

    puts
  end
end
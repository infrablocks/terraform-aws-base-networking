require 'rspec/core/rake_task'
require 'securerandom'

require_relative 'lib/terraform'

DEPLOYMENT_IDENTIFIER = SecureRandom.hex[0, 8]

Terraform::Tasks.install('0.8.6')

task :default => 'test:integration'

namespace :test do
  RSpec::Core::RakeTask.new(:integration) do
    ENV['AWS_REGION'] = 'eu-west-2'
  end
end

namespace :provision do
  desc 'Provisions module in AWS'
  task :aws, [:deployment_identifier] => ['terraform:ensure'] do |_, args|
    deployment_identifier = args.deployment_identifier || DEPLOYMENT_IDENTIFIER
    configuration_directory = Paths.from_project_root_directory('src')

    puts "Provisioning with deployment identifier: #{deployment_identifier}"

    Terraform.clean
    Terraform.apply(directory: configuration_directory, vars: {
        vpc_cidr: "10.1.0.0/16",
        region: 'eu-west-2',
        availability_zones: 'eu-west-2a,eu-west-2b',

        component: 'integration-tests',
        deployment_identifier: deployment_identifier,

        bastion_ami: 'ami-bb373ddf',
        bastion_ssh_public_key_path: 'config/secrets/keys/bastion/ssh.public',
        bastion_ssh_allow_cidrs: '86.53.244.42/32',

        domain_name: 'greasedscone.uk',
        public_zone_id: 'Z2WA5EVJBZSQ3V'
    })
  end
end

namespace :destroy do
  desc 'Destroys module in AWS'
  task :aws, [:deployment_identifier] => ['terraform:ensure'] do |_, args|
    deployment_identifier = args.deployment_identifier || DEPLOYMENT_IDENTIFIER
    configuration_directory = Paths.from_project_root_directory('src')

    puts "Destroying with deployment identifier: #{deployment_identifier}"

    Terraform.clean
    Terraform.destroy(directory: configuration_directory, vars: {
        vpc_cidr: "10.1.0.0/16",
        region: 'eu-west-2',
        availability_zones: 'eu-west-2a,eu-west-2b',

        component: 'integration-tests',
        deployment_identifier: deployment_identifier,

        bastion_ami: 'ami-bb373ddf',
        bastion_ssh_public_key_path: 'config/secrets/keys/bastion/ssh.public',
        bastion_ssh_allow_cidrs: '86.53.244.42/32',

        domain_name: 'greasedscone.uk',
        public_zone_id: 'Z2WA5EVJBZSQ3V'
    })
  end
end

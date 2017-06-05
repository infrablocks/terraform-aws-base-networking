require 'bundler/setup'

require 'awspec'
require 'support/awspec'

require 'support/shared_contexts/terraform'

require 'securerandom'
require 'netaddr'
require 'open-uri'

require_relative '../lib/terraform'

RSpec.configure do |config|
  deployment_identifier = ENV['DEPLOYMENT_IDENTIFIER']
  safe_ip_cidr = '86.53.244.42/32'

  def current_public_ip_cidr
    "#{open('http://whatismyip.akamai.com').read}/32"
  end

  config.example_status_persistence_file_path = '.rspec_status'

  config.add_setting :vpc_cidr, default: "10.1.0.0/16"
  config.add_setting :region, default: 'eu-west-2'
  config.add_setting :availability_zones, default: 'eu-west-2a,eu-west-2b'

  config.add_setting :component, default: 'integration-tests'
  config.add_setting :deployment_identifier,
      default: deployment_identifier || SecureRandom.hex[0, 8]

  config.add_setting :bastion_ami, default: 'ami-bb373ddf'
  config.add_setting :bastion_instance_type, default: 't2.medium'
  config.add_setting :bastion_ssh_public_key_path, default: 'config/secrets/keys/bastion/ssh.public'
  config.add_setting :bastion_ssh_allow_cidrs, default: "#{current_public_ip_cidr},#{safe_ip_cidr}"

  config.add_setting :domain_name, default: 'greasedscone.uk'
  config.add_setting :public_zone_id, default: 'Z4Q2X3ESOZT4N'
  config.add_setting :private_zone_id, default: 'Z2CDAFD23Q10HO'

  config.add_setting :bastion_user, default: 'centos'
  config.add_setting :bastion_ssh_private_key_path, default: 'config/secrets/keys/bastion/ssh.private'

  config.add_setting :infrastructure_events_bucket, default: 'tobyclemson-open-source'

  config.before(:suite) do
    variables = RSpec.configuration
    configuration_directory = Paths.from_project_root_directory('src')

    puts
    puts "Provisioning with deployment identifier: #{variables.deployment_identifier}"
    puts

    Terraform.clean
    Terraform.apply(directory: configuration_directory, vars: {
        vpc_cidr: variables.vpc_cidr,
        region: variables.region,
        availability_zones: variables.availability_zones,

        component: variables.component,
        deployment_identifier: variables.deployment_identifier,

        bastion_ami: variables.bastion_ami,
        bastion_instance_type: variables.bastion_instance_type,
        bastion_ssh_public_key_path: variables.bastion_ssh_public_key_path,
        bastion_ssh_allow_cidrs: variables.bastion_ssh_allow_cidrs,

        domain_name: variables.domain_name,
        public_zone_id: variables.public_zone_id,
        private_zone_id: variables.private_zone_id,

        infrastructure_events_bucket: variables.infrastructure_events_bucket
    })

    puts
  end

  config.after(:suite) do
    unless deployment_identifier
      variables = RSpec.configuration
      configuration_directory = Paths.from_project_root_directory('src')

      puts
      puts "Destroying with deployment identifier: #{variables.deployment_identifier}"
      puts

      Terraform.clean
      Terraform.destroy(
          directory: configuration_directory,
          force: true,
          vars: {
            vpc_cidr: variables.vpc_cidr,
            region: variables.region,
            availability_zones: variables.availability_zones,

            component: variables.component,
            deployment_identifier: variables.deployment_identifier,

            bastion_ami: variables.bastion_ami,
            bastion_instance_type: variables.bastion_instance_type,
            bastion_ssh_public_key_path: variables.bastion_ssh_public_key_path,
            bastion_ssh_allow_cidrs: variables.bastion_ssh_allow_cidrs,

            domain_name: variables.domain_name,
            public_zone_id: variables.public_zone_id,
            private_zone_id: variables.private_zone_id,

            infrastructure_events_bucket: variables.infrastructure_events_bucket
        })

      puts
    end
  end
end
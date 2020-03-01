require 'rspec/core/rake_task'
require 'securerandom'
require 'git'
require 'semantic'
require 'rake_terraform'

require_relative 'lib/configuration'
require_relative 'lib/version'

configuration = Configuration.new

def repo
  Git.open('.')
end

def latest_tag
  repo.tags.map do |tag|
    Semantic::Version.new(tag.name)
  end.max
end

RakeTerraform.define_installation_tasks(
    path: File.join(Dir.pwd, 'vendor', 'terraform'),
    version: '0.12.15')

task :default => 'test:integration'

namespace :test do
  RSpec::Core::RakeTask.new(:integration => ['terraform:ensure']) do
    ENV['AWS_REGION'] = 'eu-west-2'
    ENV['TF_PLUGIN_CACHE_DIR'] =
        "#{Paths.project_root_directory}/vendor/terraform/plugins"
  end
end

namespace :deployment do
  namespace :prerequisites do
    RakeTerraform.define_command_tasks(
        configuration_name: 'prerequisites',
        argument_names: [:deployment_identifier]
    ) do |t, args|
      deployment_configuration = configuration.for(:prerequisites, args)

      t.source_directory = deployment_configuration.source_directory
      t.work_directory = deployment_configuration.work_directory

      t.state_file = deployment_configuration.state_file

      t.vars = deployment_configuration.vars.to_h
    end
  end

  namespace :harness do
    RakeTerraform.define_command_tasks(
        configuration_name: 'base networking module',
        argument_names: [:deployment_identifier]
    ) do |t, args|
      deployment_configuration = configuration.for(:harness, args)

      t.source_directory = deployment_configuration.source_directory
      t.work_directory = deployment_configuration.work_directory

      t.state_file = deployment_configuration.state_file

      t.vars = deployment_configuration.vars.to_h
    end
  end
end

namespace :version do
  task :bump, [:type] do |_, args|
    next_tag = latest_tag.send("#{args.type}!")
    repo.add_tag(next_tag.to_s)
    repo.push('origin', 'master', tags: true)
    puts "Bumped version to #{next_tag}."
  end

  task :release do
    next_tag = latest_tag.release!
    repo.add_tag(next_tag.to_s)
    repo.push('origin', 'master', tags: true)
    puts "Released version #{next_tag}."
  end
end

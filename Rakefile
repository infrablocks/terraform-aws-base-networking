require 'rspec/core/rake_task'
require 'git'
require 'semantic'
require 'rake_terraform'

require_relative 'lib/configuration'

configuration = Configuration.new

RakeTerraform.define_installation_tasks(
    path: File.join(Dir.pwd, 'vendor', 'terraform'),
    version: '0.10.8')

task :default => 'test:integration'

namespace :test do
  RSpec::Core::RakeTask.new(:integration => ['terraform:ensure']) do
    ENV['AWS_REGION'] = 'eu-west-2'
  end
end

namespace :deployment do
  namespace :harness do
    RakeTerraform.define_command_tasks do |t|
      t.argument_names = [:deployment_identifier]

      t.configuration_name = 'ECS Route53 registration module'
      t.source_directory = configuration.for(:harness).source_directory
      t.work_directory = configuration.for(:harness).work_directory

      t.state_file = configuration.for(:harness).state_file

      t.vars = lambda do |args|
        configuration.for(:harness, args)
            .vars
            .to_h
      end
    end
  end
end

namespace :release do
  desc 'Increment and push tag'
  task :tag do
    repo = Git.open('.')
    tags = repo.tags
    latest_tag = tags.map { |tag| Semantic::Version.new(tag.name) }.max
    next_tag = latest_tag.increment!(:patch)
    repo.add_tag(next_tag.to_s)
    repo.push('origin', 'master', tags: true)
  end
end

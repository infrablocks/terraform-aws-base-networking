require 'spec_helper'

describe 'IGW creation' do
  include_context :terraform

  subject { igw("igw-#{variables.component}-#{variables.deployment_identifier}") }

  it { should exist }
  it { should have_tag('Component').value(variables.component) }
  it { should have_tag('DeploymentIdentifier').value(variables.deployment_identifier) }
  it { should have_tag('Tier').value('public') }

  it 'is attached to the created VPC' do
    vpc_igw = vpc("vpc-#{variables.component}-#{variables.deployment_identifier}")
        .internet_gateways.first

    expect(subject.internet_gateway_id)
        .to(eq(vpc_igw.internet_gateway_id))
  end
end

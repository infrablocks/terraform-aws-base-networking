require 'spec_helper'

describe 'IGW' do
  include_context :terraform

  let(:component) { vars.component }
  let(:dep_id) { vars.deployment_identifier }

  subject { igw("igw-#{component}-#{dep_id}") }

  it { should exist }
  it { should have_tag('Component').value(component) }
  it { should have_tag('DeploymentIdentifier').value(dep_id) }
  it { should have_tag('Tier').value('public') }

  it 'is attached to the created VPC' do
    vpc_igw = vpc("vpc-#{component}-#{dep_id}")
        .internet_gateways.first

    expect(subject.internet_gateway_id)
        .to(eq(vpc_igw.internet_gateway_id))
  end
end

require 'spec_helper'

describe 'NAT' do
  include_context :terraform

  let(:component) { vars.component }
  let(:dep_id) { vars.deployment_identifier }

  let(:availability_zones) { vars.availability_zones }

  let :created_vpc do
    vpc("vpc-#{component}-#{dep_id}")
  end
  let :first_public_subnet do
    zone = availability_zones.split(',').first
    subnet("public-subnet-#{component}-#{dep_id}-#{zone}")
  end

  subject do
    response = ec2_client.describe_nat_gateways({
        filter: [{ name: 'vpc-id', values: [created_vpc.id] }]
    })
    response.nat_gateways.single_resource(created_vpc.id)
  end

  it 'resides in the first public subnet' do
    expect(subject.subnet_id).to(eq(first_public_subnet.id))
  end

  it 'associates an EIP and exposes as an output' do
    public_ip = nat_public_ip_output
    expect(subject.nat_gateway_addresses.map(&:public_ip))
        .to(include(public_ip))
  end

  def nat_public_ip_output
    output_with_name('nat_public_ip')
  end
end

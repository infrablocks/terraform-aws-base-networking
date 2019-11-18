require 'spec_helper'

describe 'NAT' do
  let(:component) {vars.component}
  let(:dep_id) {vars.deployment_identifier}

  let(:availability_zones) {vars.availability_zones}

  let :created_vpc do
    vpc("vpc-#{component}-#{dep_id}")
  end
  let :first_public_subnet do
    zone = availability_zones.first
    subnet("public-subnet-#{component}-#{dep_id}-#{zone}")
  end

  let(:nat_public_ip_output) {output_for(:harness, 'nat_public_ip')}

  def nat_gateways
    response = ec2_client.describe_nat_gateways(
        {
            filter: [{name: 'vpc-id', values: [created_vpc.id]}]
        })
    response.nat_gateways.select { |n| n.state == 'available' }
  end

  context 'when include_nat_gateway is no' do
    before(:all) do
      reprovision(include_nat_gateway: "no")
    end

    it 'does not create a NAT gateway' do
      expect(nat_gateways).to(be_empty)
    end
    it 'does not output a NAT EIP' do
      expect(nat_public_ip_output).to(eq(''))
    end
  end

  context 'when include_nat_gateway is yes' do
    subject do
      nat_gateways.single_resource(created_vpc.id)
    end

    before(:all) do
      reprovision(include_nat_gateway: "yes")
    end

    it 'resides in the first public subnet' do
      expect(subject.subnet_id).to(eq(first_public_subnet.id))
    end

    it 'associates an EIP and exposes as an output' do
      public_ip = nat_public_ip_output

      expect(subject.nat_gateway_addresses.map(&:public_ip))
          .to(include(public_ip))
    end
  end
end

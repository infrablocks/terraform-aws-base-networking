require 'spec_helper'

describe 'NAT' do
  let(:component) {vars.component}
  let(:dep_id) {vars.deployment_identifier}

  let(:availability_zones) {vars.availability_zones}

  let :created_vpc do
    vpc("vpc-#{component}-#{dep_id}")
  end
  let :public_subnets do
    availability_zones.map do |zone|
      subnet("public-subnet-#{component}-#{dep_id}-#{zone}")
    end
  end

  let :nat_public_ips_output do
    output_for(:harness, 'nat_public_ips', parse: true)
  end

  let :nat_gateways do
    public_subnets.map do |subnet|
      ec2_client
          .describe_nat_gateways({
              filter: [
                  {name: 'vpc-id', values: [created_vpc.id]},
                  {name: 'subnet-id', values: [subnet.id]},
                  {name: 'state', values: ['available']}
              ]
          })
          .nat_gateways
          .first
    end.compact
  end

  context 'when include_nat_gateways is no' do
    before(:all) do
      reprovision(include_nat_gateways: "no")
    end

    it 'does not create a NAT gateway' do
      expect(nat_gateways).to(be_empty)
    end
    it 'does not output a NAT EIP' do
      expect(nat_public_ips_output).to(eq([]))
    end
  end

  context 'when include_nat_gateways is yes' do
    before(:all) do
      reprovision(include_nat_gateways: "yes")
    end

    it 'creates a NAT gateway in each public subnet' do
      expect(nat_gateways.length).to(eq(availability_zones.length))
    end

    it 'associates an EIP to each NAT gateway and exposes as an output' do
      nat_gateways.zip(nat_public_ips_output)
          .each do |nat_gateway, nat_public_ip_output|
      expect(nat_gateway.nat_gateway_addresses.map(&:public_ip))
          .to(include(nat_public_ip_output))
      end
    end
  end
end

require 'spec_helper'

describe 'VPC' do
  let(:component) {vars.component}
  let(:dep_id) {vars.deployment_identifier}
  let(:dependencies) {vars.dependencies}

  let(:vpc_cidr) {vars.vpc_cidr}
  let(:availability_zones) {vars.availability_zones}

  let(:private_zone_id) {vars.private_zone_id}

  let(:infrastructure_events_bucket) {vars.infrastructure_events_bucket}

  subject {vpc("vpc-#{component}-#{dep_id}")}

  let :private_hosted_zone do
    route53_client.get_hosted_zone({id: private_zone_id})
  end

  it {should exist}
  it {should have_tag('Component').value(component)}
  it {should have_tag('DeploymentIdentifier').value(dep_id)}
  it {should have_tag('Dependencies').value(dependencies.join(','))}

  its(:cidr_block) {should eq vpc_cidr}

  it 'writes the VPC ID to the provided infrastructure events bucket' do
    expected_vpc_id = subject.vpc_id

    expect(s3_bucket(infrastructure_events_bucket))
        .to(have_object("vpc-existence/#{expected_vpc_id}"))
  end

  it 'exposes the VPC ID as an output' do
    expected_vpc_id = subject.vpc_id
    actual_vpc_id = output_for(:harness, 'vpc_id')

    expect(actual_vpc_id).to(eq(expected_vpc_id))
  end

  it 'exposes the VPC CIDR block as an output' do
    expected_vpc_cidr = subject.cidr_block
    actual_vpc_cidr = output_for(:harness, 'vpc_cidr')

    expect(actual_vpc_cidr).to(eq(expected_vpc_cidr))
  end

  it 'enables DNS hostnames' do
    full_resource = Aws::EC2::Vpc.new(subject.id)
    dns_hostnames = full_resource
        .describe_attribute({attribute: 'enableDnsHostnames'})

    expect(dns_hostnames.enable_dns_hostnames.value).to be(true)
  end

  it 'exposes the availability zones as an output' do
    expected_availability_zones = availability_zones
    actual_availability_zones =
        output_for(:harness, 'availability_zones', parse: true)

    expect(actual_availability_zones).to(eq(expected_availability_zones))
  end

  it 'exposes the number of availability zones as an output' do
    expected_count = availability_zones.count.to_s
    actual_count = output_for(:harness, 'number_of_availability_zones')

    expect(actual_count).to(eq(expected_count))
  end

  context 'when include_route53_zone_association is yes' do
    before(:all) do
      reprovision(include_route53_zone_association: "yes")
    end

    it 'associates the supplied private hosted with the VPC' do
      expect(private_hosted_zone.vp_cs.map(&:vpc_id)).to(include(subject.id))
    end
  end

  context 'when include_route53_zone_association is no' do
    before(:all) do
      reprovision(include_route53_zone_association: "no", private_zone_id: '')
    end

    it 'does not associate the supplied private hosted with the VPC' do
      expect(private_hosted_zone.vp_cs.map(&:vpc_id)).not_to(include(subject.id))
    end
  end
end

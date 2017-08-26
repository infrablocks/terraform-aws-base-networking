require 'spec_helper'
require 'net/ssh'

describe 'Bastion' do
  let(:component) { vars.component }
  let(:dep_id) { vars.deployment_identifier }

  let(:vpc_cidr) { vars.vpc_cidr }
  let(:availability_zones) { vars.availability_zones }

  let(:bastion_ami) { vars.bastion_ami }
  let(:bastion_instance_type) { vars.bastion_instance_type }
  let(:bastion_user) { vars.bastion_user }
  let(:bastion_ssh_allow_cidrs) { vars.bastion_ssh_allow_cidrs }
  let(:bastion_ssh_private_key_path) { vars.bastion_ssh_private_key_path }

  let(:domain_name) { vars.domain_name }
  let(:public_zone_id) { vars.public_zone_id }

  subject { ec2("bastion-#{component}-#{dep_id}") }

  let :created_vpc do
    vpc("vpc-#{component}-#{dep_id}")
  end

  let :first_public_subnet do
    zone = availability_zones.split(',').first
    subnet("public-subnet-#{component}-#{dep_id}-#{zone}")
  end

  let :bastion_security_group do
    security_group("bastion-#{component}-#{dep_id}")
  end

  let :open_to_bastion_security_group do
    security_group("open-to-bastion-#{component}-#{dep_id}")
  end

  it { should exist }
  it { should belong_to_vpc("vpc-#{component}-#{dep_id}")}
  its(:subnet_id) { should eq(first_public_subnet.id) }
  its(:image_id) { should eq(bastion_ami) }
  its(:instance_type) { should eq(bastion_instance_type) }

  its(:key_name) { should eq("bastion-#{component}-#{dep_id}") }

  it { should have_tag('Component').value(component) }
  it { should have_tag('DeploymentIdentifier').value(dep_id) }
  it { should have_tag('Role').value('bastion') }

  it 'associates an EIP and exposes as an output' do
    public_ip = bastion_public_ip_output
    expect(subject).to(have_eip(public_ip))
  end

  it 'creates a public DNS entry for the bastion' do
    public_ip = bastion_public_ip_output
    zone = route53_hosted_zone(public_zone_id)
    expect(zone)
        .to(have_record_set("bastion-#{component}-#{dep_id}.#{domain_name}.")
                .a(public_ip)
                .ttl(60))
  end

  context 'bastion security group' do
    it 'exists' do expect(bastion_security_group).to(exist) end

    it 'has Component tag' do
      expect(bastion_security_group)
          .to(have_tag('Component').value(component))
    end

    it 'has DeploymentIdentifier tag' do
      expect(bastion_security_group)
          .to(have_tag('DeploymentIdentifier').value(dep_id))
    end

    it 'is associated with the created VPC' do
      expect(bastion_security_group.vpc_id).to(eq(created_vpc.id))
    end

    it 'is associated with the bastion' do
      expect(subject).to(have_security_group("bastion-#{component}-#{dep_id}"))
    end

    it 'allows inbound SSH for each supplied CIDR' do
      allowed_cidrs = bastion_ssh_allow_cidrs.split(',')
      allowed_cidrs.each do |cidr|
        ingress_rule = bastion_security_group.ip_permissions.find do |perm|
          perm.ip_ranges.map(&:cidr_ip).include?(cidr)
        end

        expect(ingress_rule.from_port).to(eq(22))
        expect(ingress_rule.to_port).to(eq(22))
        expect(ingress_rule.ip_protocol).to(eq('tcp'))
      end

      expect(bastion_security_group.inbound_rule_count).to(eq(allowed_cidrs.count))
    end

    it 'allows outbound SSH to the VPC CIDR' do
      expect(bastion_security_group.outbound_rule_count).to(be(1))
      egress_rule = bastion_security_group.ip_permissions_egress.first

      expect(egress_rule.from_port).to(eq(22))
      expect(egress_rule.to_port).to(eq(22))
      expect(egress_rule.ip_protocol).to(eq('tcp'))
      expect(egress_rule.ip_ranges.map(&:cidr_ip)).to(eq([vpc_cidr]))
    end
  end

  context 'open-to-bastion security group' do
    it 'exists' do expect(open_to_bastion_security_group).to(exist) end

    it 'has Component tag' do
      expect(open_to_bastion_security_group)
          .to(have_tag('Component').value(component))
    end

    it 'has DeploymentIdentifier tag' do
      expect(open_to_bastion_security_group)
          .to(have_tag('DeploymentIdentifier').value(dep_id))
    end

    it 'is associated with the created VPC' do
      expect(open_to_bastion_security_group.vpc_id).to(eq(created_vpc.id))
    end

    it 'allows inbound SSH from the bastion' do
      permission = open_to_bastion_security_group.ip_permissions.find do |permission|
        permission.user_id_group_pairs.find do |pair|
          pair.group_id == bastion_security_group.id
        end
      end

      expect(permission).not_to(be(nil))
      expect(permission.from_port).to(eq(22))
      expect(permission.to_port).to(eq(22))
      expect(permission.ip_protocol).to(eq('tcp'))
    end
  end

  context 'connectivity' do
    it 'is reachable using the corresponding private SSH key' do
      expect {
        ssh = Net::SSH.start(
            "bastion-#{component}-#{dep_id}.#{domain_name}",
            user = bastion_user,
            options = {
                keys: bastion_ssh_private_key_path
            })
        ssh.exec!('ls -al')
        ssh.close
      }.not_to raise_error
    end
  end

  def bastion_public_ip_output
    output_with_name('bastion_public_ip')
  end
end

# frozen_string_literal: true

RSpec::Matchers.define :a_cidr_block_within do |parent_cidr_block|
  def of_size(size)
    @size = size
    self
  end

  match do |child_cidr_block|
    parent_cidr = NetAddr::IPv4Net.parse(parent_cidr_block)
    child_cidr = NetAddr::IPv4Net.parse(child_cidr_block)

    parent_relationship = parent_cidr.rel(child_cidr)

    if @size
      netmask = NetAddr::Mask32.parse(@size)
      netmask_difference = child_cidr.netmask.cmp(netmask)

      return parent_relationship == 1 && netmask_difference == 0
    end

    return parent_relationship == 1
  end
end

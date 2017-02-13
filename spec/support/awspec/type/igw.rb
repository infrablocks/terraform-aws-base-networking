module Awspec::Type
  class Igw < Base
    include Awspec::Helper::Finder
    
    aws_resource Aws::EC2::InternetGateway
    tags_allowed

    def resource_via_client
      method(:find_igw).owner
      @resource_via_client ||= find_igw(@display_name)
    end

    def id
      @id ||= resource_via_client.internet_gateway_id if resource_via_client
    end
  end
end
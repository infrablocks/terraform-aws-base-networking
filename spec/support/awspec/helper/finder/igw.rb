module Awspec::Helper
  module Finder
    module Igw
      def find_igw(id)
        res = ec2_client.describe_internet_gateways({
            filters: [{ name: 'internet-gateway-id', values: [id] }]
        })
        resource = res.internet_gateways.single_resource(id)
        return resource if resource
        res = ec2_client.describe_internet_gateways({
            filters: [{ name: 'tag:Name', values: [id] }]
        })
        res.internet_gateways.single_resource(id)
      end
    end
  end
end
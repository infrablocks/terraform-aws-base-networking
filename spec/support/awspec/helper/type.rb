require_relative '../type/igw'

module Awspec
  module Helper
    module Type
      def igw(*args)
        name = args.first
        Awspec::Type::Igw.new(name)
      end
    end
  end
end

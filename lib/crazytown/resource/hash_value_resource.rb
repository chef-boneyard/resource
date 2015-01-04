module Crazytown
  require 'crazytown/resource'

  module Resource
    module HashValueResource
      include Accessor

      def initialize(parent_resource, key, *args, &block)
        super(parent_resource, *args, &block)
        @hash_key = key
      end

      attr_reader :hash_key

      def original_value
        if defined(@original_value)
          @original_value
        else
          parent_resource.original_value[hash_key]
        end
      end

      def self.set_value(parent_resource, key, *args, &block)
        super(*args, &block)
      end

      def self.delete_value(parent_resource, key)
        super()
      end
    end
  end
end

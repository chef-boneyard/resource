require 'chef_resource/type'

module ChefResource
  module Types
    class StringType
      extend Type

      must_be_kind_of String

      def self.coerce(parent, value)
        value = value.to_s unless value.nil?
        super
      end
    end
  end
end

require 'crazytown/type'

module Crazytown
  module Type
    class StringType
      extend Type

      must_be_kind_of String

      def self.coerce(value)
        value = value.to_s unless value.nil?
        super
      end
    end
  end
end

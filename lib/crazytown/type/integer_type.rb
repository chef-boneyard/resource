require 'crazytown/type'

module Crazytown
  module Type
    #
    # Handles Integer types.
    #
    # Supports base and digits.
    #
    class IntegerType
      extend Type

      must_be_kind_of Integer

      def self.coerce(value)
        # TODO valid int regex
        if value.is_a?(String) && ((!base || base <= 10) && value =~ /^\d+$/)
          if base
            value = value.to_i(base)
          else
            value = value.to_i
          end
        end
        super
      end

      def self.value_to_s(value)
        str = base ? value.to_s(base) : value.to_s
        str = str.rjust(digits, '0') if digits
        str
      end

      class <<self
        extend SimpleStruct
        attribute :base
        attribute :digits
      end
    end
  end
end

require 'crazytown/type'

module Crazytown
  module Type
    #
    # Handles Float types.
    #
    # Supports strings and number types.
    #
    class FloatType
      extend Type

      must_be_kind_of Float

      def self.coerce(value)
        # TODO valid float regex
        if value.is_a?(String)
          value = value.to_f
        end
        super
      end
    end
  end
end

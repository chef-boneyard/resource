require 'chef_resource/type'

module ChefResource
  module Types
    #
    # Handles Float types.
    #
    # Supports strings and number types.
    #
    class FloatType
      extend Type

      must_be_kind_of Float

      def self.coerce(parent, value)
        if value.is_a?(String)
          if value !~ /^[+-]?(\d+(\.\d+)?|.\d+)(e[+-]?\d+)?$/i
            raise ValidationError.new("not a valid floating point string", value)
          end
          value = value.to_f
        elsif value.is_a?(Numeric)
          value = value.to_f
        end
        super
      end
    end
  end
end

require 'chef_resource/type'

module ChefResource
  module Types
    #
    # Handles Integer types.
    #
    # Supports parse / to_s in bases other than 10.
    #
    class IntegerType
      extend Type

      must_be_kind_of Integer

      def self.coerce(parent, value)
        if value.is_a?(String)
          if !base_regexp.match(value)
            raise ValidationError.new("must be a base #{base||10} string", value)
          end

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
        str
      end

      def self.base_regexp
        base = self.base || 10
        if base <= 10
          /^[-+]?[0-#{base-1}]+$/
        elsif base <= 36
          top_char = ('a'.ord + base-11).chr
          /^[-+]?[0-9a-#{top_char}]+$/i
        else
          raise "Base #{base} strings not supported: nothing bigger than 36!"
        end
      end

      class <<self
        extend SimpleStruct
        property :base
      end
    end
  end
end

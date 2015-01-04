require 'crazytown/type/type_init'

module Crazytown
  module Type
    module BooleanType
      extend TypeType

      def to_value(value)
        value = super
        if ![true, false, nil].include?(value)
          raise ArgumentError, "Boolean must be true or false!"
        end
        value
      end

      require 'crazytown/type/type_type'
    end
  end
end

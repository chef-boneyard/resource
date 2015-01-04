require 'crazytown/type/type_init'

module Crazytown
  module Type
    #
    # Type used to handle raw Symbols.  If you pass a String (or anything with
    # `.to_sym`) it will automatically convert it to a Symbol.
    #
    # TODO bad name.  SymbolType implies *instances* are Symbol Types, not that
    # the class is.
    #
    module SymbolType
      extend TypeType

      def to_value(value)
        if value.nil?
          nil
        else
          value.to_sym
        end
      end

      require 'crazytown/type/type_type'
    end
  end
end

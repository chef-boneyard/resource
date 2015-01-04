# Used in Value, Struct, Type, StructType and TypeType to resolve circles
require 'crazytown/type/type_init'
require 'crazytown/struct'

module Crazytown
  module Type
    #
    # A StructType.  Meant to be included in a module or class.
    #
    module StructType
      include Type
      extend TypeType
      value_module Struct

      TypeInit.bootstrap_type_system

      require 'crazytown/type/struct_attribute_type'
      attribute :attributes, ::Hash[Symbol => StructAttributeType]

      def attribute(name, type, *args, &block)
        attributes[:attributes].store(name, self, name, type, *args, &block)
      end
    end
  end
end

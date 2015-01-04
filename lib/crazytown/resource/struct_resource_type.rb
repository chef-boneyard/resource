module Crazytown
  require 'crazytown/resource'

  module Resource
    #
    # A Struct resource has well-defined *attributes* with getters and setters.
    #
    # Getters
    # =======
    # Getters let you retrieve the value of an attribute.  For example:
    #
    # ```ruby
    # class Person < StructResourceBase
    #   attribute :name, String
    #   attribute :aliases, Array[String]
    # end
    # Person.new do
    #   name 'Alice'
    #   aliases []
    # end
    # person.name # Alice
    # person.aliases # []
    # ```
    #
    module StructResourceType
      include ResourceType

      def attribute(name, resource_type=ValueResource, &override)
        attribute_types.store(self, name, resource_type, &override)
      end

      # Normally, we would use `attribute` here, but attribute_types requires
      # a more delicate touch (since it's used as part of `attribute` itself)
      StructAttributeType.create(:attribute_types, HashResourceClass) do
        def key_type
          SymbolResource
        end
        def value_type
          StructAttributeType
        end
      end
    end
  end
end

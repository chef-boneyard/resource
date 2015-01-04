module Crazytown
  require 'crazytown/resource'

  module Resource
    class ResourceClass < Class
      include ResourceType
      extend StructResourceType

      #
      # @param parent_resource The parent module in which the module will reside (assumed to be the caller if not passed)
      # @param name The name of the new module
      #
      # create_recipe(parent_resource, :name, [, supertype]) { ... }
      # create_recipe(:name, [, supertype]) { ... }
      #
      def self.create_recipe(parent_resource, name=nil, &override)
        if parent_resource.is_a?(Symbol)
          name = parent_resource
          parent_resource = override.instance_variable_get('self')
        end

        result = Class.new(self, &override)
        result.resource_module_name name
        result
      end

      def original_value
        superclass
      end
    end
  end
end

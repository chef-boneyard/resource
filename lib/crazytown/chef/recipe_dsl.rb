module Crazytown
  module Chef
    #
    # Adds `resource_type` to create new resource types.
    #
    # Must be in a module or class.
    #
    module RecipeDSL
      def resource_types
        @resource_types ||= {}
      end

      def resource_type(name, resource_class)
        name = name.to_sym
        resource_types[name] = resource_class
        module_eval <<-EOM
          def #{name}(*identity, &update_block)
            self.class.create_resource(name, *identity, &update_block)
          end
        EOM
      end

      def remove_resource_type(name)
        name = name.to_sym
        resource_types.delete(name)
        remove_method(name)
      end

      def create_resource(name, *identity, &update_block)
        resource = resource_types[name].open(*identity)
        resource.define(&update_block)
        resource
      end
    end
  end
end

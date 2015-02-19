module ChefResource
  module ChefDSL
    module ResourceContainerModule
      attr_reader :recipe_dsl_module

      def resource_types
        @resource_types ||= {}
      end

      # TODO also run this after libraries/ are parsed, and perhaps when method_missing
      # is triggered.
      def update_resource_definition_methods!
        const_module = self

        # Go through the constants in the module, trawling for Resources
        seen = []
        const_module.constants.each do |class_name|
          resource_class = const_module.const_get(class_name)
          next if !resource_class.is_a?(Class)
          next if !(resource_class <= Chef::Resource)

          resource_name = resource_class.dsl_name

          seen << resource_name

          # Detect conflicts: two Resources with the same resource_name
          current_class_name = resource_types[resource_name]
          if current_class_name != class_name
            if current_class_name && const_module.const_defined?(current_class_name)
              current_resource = const_module.const_get(current_class_name)
              if current_resource != resource_class && current_resource.is_a?(Class) && current_resource <= Chef::Resource && current_resource_name == resource_name
                raise "Both #{current_class_name} and #{class_name} map to #{resource_name}.  Choose a different dsl_name for one of them!"
              end
            end

            # We don't overwrite real methods in the recipe DSL (if any?)
            if !current_class_name && method_defined?(resource_name)
              raise "Method #{resource_name} already exists in #{recipe_dsl_module}!  Not overwriting with resource definition for #{class_name}."
            end

            # Create / overwrite the current methods
            emit_resource_definition_method(resource_name, class_name, resource_class)

            resource_types[resource_name] = class_name
          end
        end

        # Remove methods for constants that no longer exist
        (seen - resource_types.keys).each do |resource_name|
          const_module.remove_method(resource_name)
          resource_types.delete(resource_name)
        end
      end

      def emit_resource_definition_method(resource_name, class_name, actual_class)
        # TODO handle definitions too?
        if actual_class <= ChefResource::Resource
          recipe_dsl_module.module_eval <<-EOM, __FILE__, __LINE__+1
            def #{resource_name}(*identity, &update_block)
              # TODO fix Chef: let declare_resource take the resource class
              if update_block
                declare_resource(#{actual_class.name}, *identity, caller[0], &update_block)
              else
                # If you don't pass a block, we assume you just wanted to construct
                # a resource to use for reading.
                build_resource(#{actual_class.name}, *identity, caller[0])
              end
            end
          EOM
        else
          recipe_dsl_module.module_eval <<-EOM, __FILE__, __LINE__+1
            def #{resource_name}(name, &block)
              declare_resource(#{resource_name.inspect}, name, caller[0], &block)
            end
          EOM
        end
      end
    end
  end
end

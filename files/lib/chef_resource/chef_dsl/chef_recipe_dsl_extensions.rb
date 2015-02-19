require 'chef_resource/resource'

module ChefResource
  module ChefDSL
    module ChefRecipeDSLExtensions
      #
      # Allow ChefResource resources to be declared with a different syntax:
      #
      # declare_resource(:resource, ..., created_at)
      # declare_resource(ResourceClass, ..., created_at)
      #
      # Which translates to open() in the end.
      #
      def declare_resource(type, *identity, created_at, &update_block)
        resource_class = resource_class_for(type)

        # Handle normal resources
        if !resource_class.is_a?(ChefResource::Resource)
          case identity.size
          when 0
            name, created_at = created_at, caller[0]
          when 1
            name = identity[0]
          else
            raise ArgumentError, "wrong number of arguments (#{identity.size+1} for 1..2)"
          end
          return super(type, name, created_at, &update_block)
        end

        # ChefResource resources!
        resource = buildbuild_resource_v2(resource_class, *identity, created_at, &update_block)
        run_context.resource_collection.insert(resource,
          resource_type: resource_class.dsl_name,
          instance_name: resource.resource_identity_string)
      end

      def build_resource(type, *identity, created_at, &update_block)
        resource_class = resource_class_for(type)
        if !resource_class.is_a?(ChefResource::Resource)
          # Handle normal resources
          case identity.size
          when 0
            name, created_at = created_at, caller[0]
          when 1
            name = identity[0]
          else
            raise ArgumentError, "wrong number of arguments (#{identity.size+1} for 1..2)"
          end
          return super(type, name, created_at, &update_block)
        end

        # ChefResource!
        buildbuild_resource_v2(resource_class, *identity, created_at, &update_block)
      end

      def buildbuild_resource_v2(resource_class, *identity, created_at, &update_block)
        resource = resource_class.open(*identity)
        resource.run_context = run_context
        resource.cookbook_name = cookbook_name
        resource.recipe_name = recipe_name
        resource.source_line = created_at
        resource.declared_type = resource_class.dsl_name
        # Determine whether this resource is being created in the context of an enclosing Provider
        resource.enclosing_provider = self.is_a?(Chef::Provider) ? self : nil
        resource.params = @params

        # Evaluate resource attribute DSL
        resource.instance_eval(&update_block) if block_given?

        # Freeze resource
        resource.resource_fully_defined

        # Run optional resource hook
        resource.after_created

        resource
      end

      def resource_class_for(type)
        type.is_a?(Class) ? type : super
      end
    end
  end
end

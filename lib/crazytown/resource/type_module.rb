module Crazytown
  require 'crazytown/resource'
  require 'crazytown/bootstrap_'
  require 'crazytown/resource_type'

  module Resource
    #
    # A TypeModule instance is a Type *and* a module.  It manipulates instances
    # that store modification state.
    #
    class TypeModule < Module
      # The module itself is-a struct; however, the Type it represents can be anything.
      include Struct

      extend StructResourceType

      attribute :resource_supertype, ResourceTypeType

      def self.coerce(parent_module, name=nil, supertype=nil, &override)
        if parent_resource.is_a?(Symbol)
          name = parent_resource
          parent_resource = override.instance_variable_get('self')
        end

        # Create the class
        case supertype
        when Class
          super(supertype)
        else
          super()
          include supertype if supertype
        end
        class_eval(&block)
      end
    end
  end
end

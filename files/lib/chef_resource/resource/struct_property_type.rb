require 'chef_resource/type'
require 'chef_resource/simple_struct'

module ChefResource
  module Resource
    #
    # Struct properties all create a class for each property.  This is
    # included in that class, and StructPropertyType is extended in that class.
    #
    module StructPropertyType
      include Type

      extend SimpleStruct

      #
      # The name of this property
      #
      property :property_name

      #
      # The type of this property
      #
      property :property_type

      #
      # The parent type (struct type) of this property
      #
      property :property_parent_type

      #
      # True if this is an identity property.
      #
      boolean_property :identity

      #
      # True if this property is required.
      #
      # Required identity properties can be specified positionally in `open`,
      # like so: `FileResource.open('/x/y.txt')` is equivalent to
      # `FileResource.open(path: '/x/y.txt')`
      #
      # By default, this is false for most properties, but true for identity
      # properties that have no default set.
      #
      boolean_property :required, default: "identity? && !defined?(@default)"

      #
      # A block which loads the property from reality.
      #
      # @param value The load proc.  If this is a LazyProc, the block will
      #   be run in the context of the struct (`struct.instance_eval`) unless
      #   the block is explicitly set to `should_instance_eval: false`.  If it is not,
      #   it will always be instance_eval'd.
      #
      block_property :load_value

      #
      # Return a value of this type by coercion or construction.
      #
      # @param args The value to coerce or the values to construct with.
      # @return A value of this Type.
      #
      def coerce(parent, *args)
        property_type.is_a?(ResourceType) ? property_type.coerce(*args) : super
      end

      #
      # Emit property methods into the struct class (property_parent_type)
      #
      def emit_property_methods
        name = property_name
        class_name = CamelCase.from_snake_case(name)
        property_parent_type.class_eval <<-EOM, __FILE__, __LINE__+1
          def #{name}(*args)
            if args.empty?
              #{class_name}.get_property(self)
            else
              #{class_name}.set_property(self, *args)
            end
          end
        EOM

        property_parent_type.class_eval <<-EOM, __FILE__, __LINE__+1
          def #{name}=(value)
            #{class_name}.set_property(self, value)
          end
        EOM
      end

      #
      # Set the property value.
      #
      def set_property(struct, *args)
        if identity?
          if struct.resource_state && struct.resource_state != :created
            raise PropertyDefinedError.new("Cannot modify identity property #{property_name} of #{struct.class}: identity properties cannot be modified after the resource's identity is defined.  (State: #{struct.resource_state})", struct, self)
          end
        else
          if struct.resource_state && struct.resource_state != :created && struct.resource_state != :identity_defined
            raise PropertyDefinedError.new("Cannot modify property #{property_name} of #{struct.class}: identity properties cannot be modified after the resource's identity is defined.  (State: #{struct.resource_state})", struct, self)
          end
        end
        if args.size == 1 && args[0].is_a?(ChefResource::LazyProc)
          struct.explicit_property_values[property_name] = args[0]
        else
          struct.explicit_property_values[property_name] = coerce(struct, *args)
        end
      end

      #
      # Get the property value from the struct.
      #
      # First tries to get the desired value.  If there is none, tries to get
      # the actual value from the struct.  If the actual value doesn't have
      # the value, it looks for a load_value method.  Finally, if that isn't
      # there, it runs default.
      #
      def get_property(struct)
        value = struct.explicit_property_values.fetch(property_name) do
          return current_property_value(struct)
        end
        coerce_to_user(struct, value)
      end

      #
      # Get the current property value from the struct (i.e. the value not
      # counting anything the user has actually set--including actual value
      # and default value).
      #
      # @param struct The struct we're loading from
      #
      def current_property_value(struct)
        # Try to grab a known (non-default) value from current_resource
        has_value, value = explicit_current_property_value(struct)
        if !has_value
          value = default(parent: struct)
        end
        coerce_to_user(struct, value)
      end

      #
      # Ensure the current value of the property is loaded and set.
      #
      # @param struct The struct we're loading from
      # @return [Boolean, Value] `true, <value>` if the current_resource exists and has that explicit value, `false, nil` if not
      # @raise Any error raised by load_value or load will pass through.
      #
      def explicit_current_property_value(struct)
        # First get current_struct
        current_struct = struct.is_current_resource? ? struct : struct.current_resource
        if !current_struct
          return [ false, nil ]
        end

        # First, check quickly if we already have it.
        if current_struct.explicit_property_values.has_key?(property_name)
          return [ true, current_struct.public_send(property_name) ]
        end

        if current_struct.resource_exists?
          # Since we were already brought up, we must already be loaded, yet the
          # property isn't there.  Use load_value if it has it.
          if !load_value
            return [ false, nil ]
          end

          struct.log.load_value_started(property_name)

          begin
            value = load_value.get(instance: current_struct, instance_eval_by_default: true)
            # Set the value (if it gets coerced, catch the result)
            value = current_struct.public_send(property_name, value)
            struct.log.load_value_succeeded(property_name)
            return [ true, value ]
          rescue
            # short circuit this from happening again
            current_struct.explicit_property_values[property_name] = nil
            struct.log.load_value_failed(property_name, $!)
            raise
          end
        end
      end
    end
  end
end

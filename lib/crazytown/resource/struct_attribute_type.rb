require 'crazytown/type'
require 'crazytown/simple_struct'

module Crazytown
  module Resource
    #
    # Struct attributes all create a class for each attribute.  This is
    # included in that class, and StructAttributeType is extended in that class.
    #
    module StructAttributeType
      include Type

      extend SimpleStruct

      #
      # The name of this attribute
      #
      attribute :attribute_name

      #
      # The type of this attribute
      #
      attribute :attribute_type

      #
      # The parent type (struct type) of this attribute
      #
      attribute :attribute_parent_type

      #
      # True if this is an identity attribute.
      #
      boolean_attribute :identity

      #
      # True if this attribute is required.
      #
      # Required identity attributes can be specified positionally in `open`,
      # like so: `FileResource.open('/x/y.txt')` is equivalent to
      # `FileResource.open(path: '/x/y.txt')`
      #
      # By default, this is false for most attributes, but true for identity
      # attributes that have no default set.
      #
      boolean_attribute :required, default: "identity? && !defined?(@default)"

      #
      # A block which loads the attribute from reality.
      #
      # @param value The load proc.  If this is a LazyProc, the block will
      #   be run in the context of the struct (`struct.instance_eval`) unless
      #   the block is explicitly set to `instance_eval: false`.  If it is not,
      #   it will always be instance_eval'd.
      #
      block_attribute :load_value

      #
      # Return a value of this type by coercion or construction.
      #
      # @param args The value to coerce or the values to construct with.
      # @return A value of this Type.
      #
      def coerce(parent, *args)
        attribute_type.is_a?(ResourceType) ? attribute_type.coerce(*args) : super
      end

      #
      # Emit attribute methods into the struct class (attribute_parent_type)
      #
      def emit_attribute_methods
        name = attribute_name
        class_name = CamelCase.from_snake_case(name)
        attribute_parent_type.class_eval <<-EOM, __FILE__, __LINE__+1
          def #{name}(*args)
            if args.empty?
              #{class_name}.get_attribute(self)
            else
              #{class_name}.set_attribute(self, *args)
            end
          end
        EOM

        attribute_parent_type.class_eval <<-EOM, __FILE__, __LINE__+1
          def #{name}=(value)
            #{class_name}.set_attribute(self, value)
          end
        EOM
      end

      #
      # Set the attribute value.
      #
      def set_attribute(struct, *args)
        if identity?
          if struct.resource_state != :created
            raise AttributeDefinedError.new("Cannot modify identity attribute #{attribute_name} of #{struct.class}: identity attributes cannot be modified after the resource's identity is defined.  (State: #{struct.resource_state})", struct, self)
          end
        else
          if struct.resource_state != :created && struct.resource_state != :identity_defined
            raise AttributeDefinedError.new("Cannot modify attribute #{attribute_name} of #{struct.class}: identity attributes cannot be modified after the resource's identity is defined.  (State: #{struct.resource_state})", struct, self)
          end
        end
        if args.size == 1 && args[0].is_a?(Crazytown::LazyProc)
          struct.explicit_values[attribute_name] = args[0]
        else
          struct.explicit_values[attribute_name] = coerce(struct, *args)
        end
      end

      #
      # Get the attribute value from the struct.
      #
      # First tries to get the desired value.  If there is none, tries to get
      # the actual value from the struct.  If the actual value doesn't have
      # the value, it looks for a load_value method.  Finally, if that isn't
      # there, it runs default.
      #
      def get_attribute(struct)
        value = struct.explicit_values.fetch(attribute_name) do
          return current_attribute_value(struct)
        end
        coerce_to_user(struct, value)
      end

      #
      # Get the current attribute value from the struct (i.e. the value not
      # counting anything the user has actually set--including actual value
      # and default value).
      #
      # @param struct The struct we're loading from
      #
      def current_attribute_value(struct)
        # Try to grab a known (non-default) value from current_resource
        current_struct = struct.current_resource
        has_value, value = explicit_current_attribute_value(struct)
        if !has_value
          value = default(parent: struct)
        end
        coerce_to_user(struct, value)
      end

      #
      # Ensure the current value of the attribute is loaded and set.
      #
      # @param struct The struct we're loading from
      # @return [Boolean, Value] `true, <value>` if the current_resource exists and has that explicit value, `false, nil` if not
      # @raise Any error raised by load_value or load will pass through.
      #
      def explicit_current_attribute_value(struct)
        if !struct.current_resource || !struct.resource_exists?
          return [ false, nil ]
        end

        current_struct = struct.current_resource

        # First, check quickly if we already have it.
        if current_struct.explicit_values.has_key?(attribute_name)
          return [ true, current_struct.public_send(attribute_name) ]
        end

        # Since we were already brought up, we must already be loaded, yet the
        # attribute isn't there.  Use load_value if it has it.
        if !load_value
          return [ false, nil ]
        end

        struct.log.load_value_started(attribute_name)

        begin
          value = load_value.get(instance: current_struct, instance_eval_by_default: true)
          # Set the value (if it gets coerced, catch the result)
          value = current_struct.public_send(attribute_name, value)
          struct.log.load_value_succeeded(attribute_name)
          return [ true, value ]
        rescue
          # short circuit this from happening again
          current_struct.explicit_values[attribute_name] = nil
          struct.log.load_value_failed(attribute_name, $!)
          raise
        end
      end
    end
  end
end

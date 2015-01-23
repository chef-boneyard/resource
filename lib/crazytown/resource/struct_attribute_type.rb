require 'crazytown/resource/type'
require 'crazytown/lazy_proc'

module Crazytown
  module Resource
    #
    # Struct attributes all create a class for each attribute.  This is
    # included in that class, and StructAttributeType is extended in that class.
    #
    module StructAttributeType
      include Type

      #
      # The name of this attribute
      #
      attr_accessor :attribute_name

      #
      # The type of this attribute
      #
      attr_accessor :attribute_type

      #
      # The parent type (struct type) of this attribute
      #
      attr_accessor :attribute_parent_type

      #
      # Tell whether a value is already of this type.
      #
      def implemented_by?(instance)
        return true if !attribute_type
        instance.nil? || instance.is_a?(attribute_type)
      end

      def coerce(*args)
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
          struct.explicit_values[attribute_name] = coerce(*args)
        end
      end

      #
      # Get the attribute value from the struct.
      #
      # First tries to get the desired value.  If there is none, tries to get
      # the actual value from the struct.  If the actual value doesn't have
      # the value, it looks for a load_value method.  Finally, if that isn't
      # there, it runs default_value.
      #
      def get_attribute(struct)
        value = struct.explicit_values.fetch(attribute_name) do
          return base_attribute_value(struct)
        end
        if value.is_a?(Crazytown::LazyProc)
          coerce(value.get(instance: struct))
        else
          value
        end
      end

      #
      # Get the base attribute value from the struct (i.e. the value not
      # counting anything the user has actually set--including actual value
      # and default value).
      #
      # @param struct The struct we're loading from
      #
      def base_attribute_value(struct)
        # Try to grab a known (non-default) value from base_resource
        base_struct = struct.base_resource
        has_value, value = base_explicit_value(struct)
        if !has_value
          value = default
        end
        delazify(struct, value)
      end

      #
      # Expand values if they are lazy.  Used for final output of a value.
      #
      def delazify(struct, value)
        if value.is_a?(Crazytown::LazyProc)
          coerce(value.get(instance: struct))
        else
          value
        end
      end

      #
      # Ensure the base value of the attribute is loaded and set.
      #
      # @param struct The struct we're loading from
      # @return [Boolean, Value] `true, <value>` if the base_resource exists and has that explicit value, `false, nil` if not
      # @raise Any error raised by load_value or load will pass through.
      #
      def base_explicit_value(struct)
        if !struct.base_resource || !struct.resource_exists?
          return [ false, nil ]
        end

        base_struct = struct.base_resource

        # First, check quickly if we already have it.
        if base_struct.explicit_values.has_key?(attribute_name)
          return [ true, base_struct.public_send(attribute_name) ]
        end

        # Since we were already brought up, we must already be loaded, yet the
        # attribute isn't there.  Use load_value if it has it.
        if !load_value
          return [ false, nil ]
        end

        struct.log.load_value_started(attribute_name)

        begin
          if load_value.is_a?(Crazytown::LazyProc)
            value = load_value.get(instance: base_struct)
          else
            value = base_struct.instance_eval(&load_value)
          end
          # Set the value (if it gets coerced, catch the result)
          value = base_struct.public_send(attribute_name, value)
          struct.log.load_value_succeeded(attribute_name)
          return [ true, value ]
        rescue
          # short circuit this from happening again
          base_struct.explicit_values[attribute_name] = nil
          struct.log.load_value_failed(attribute_name, $!)
          raise
        end
      end

      #
      # Set to true if this is an identity attribute.
      #
      def identity=(value)
        @identity = value
      end

      #
      # True if this is an identity attribute.
      #
      def identity?
        @identity
      end

      #
      # Set to false if this attribute is not required (defaults to true).
      #
      def required=(value)
        @required = value
      end

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
      def required?
        if defined?(@required)
          @required
        elsif identity? && !defined?(@default)
          true
        else
          false
        end
      end

      #
      # The default value for things of this type.
      #
      # @param value The default value.  If this is a LazyProc, the block will
      #   be run in the context of the struct (`struct.instance_eval`) unless
      #   the block is explicitly set to `instance_eval: false`.
      #
      def default(value=NOT_PASSED, &block)
        if block
          @default = LazyProc.new(:instance_eval, &block)
        elsif value == NOT_PASSED
          @default
        else
          if value.is_a?(LazyProc)
            # Flip on instance_eval if it's not set, so you can say
            # default: lazy { ... } and it does the expected thing.
            value.instance_eval = true if !value.instance_eval_set?
          else
            value = coerce(value)
          end
          @default = value
        end
      end
      def default=(value)
        default(value)
      end

      #
      # A block which loads the attribute from reality.
      #
      # @param value The load proc.  If this is a LazyProc, the block will
      #   be run in the context of the struct (`struct.instance_eval`) unless
      #   the block is explicitly set to `instance_eval: false`.  If it is not,
      #   it will always be instance_eval'd.
      #
      def load_value(value=NOT_PASSED, &block)
        if block
          @load_value = block
        elsif value == NOT_PASSED
          @load_value
        else
          if value.is_a?(LazyProc)
            # Flip on instance_eval if it's not set, so you can say
            # load_value: lazy { ... } and it does the expected thing.
            value.instance_eval = true if !value.instance_eval_set?
          else
            value = coerce(value)
          end
          @load_value = value
        end
      end
      def load_value=(value)
        load_value(value)
      end
    end
  end
end

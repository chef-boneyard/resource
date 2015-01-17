require 'crazytown/chef/type'

module Crazytown
  module Chef
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
                # If we have arguments, grab the new desired value and set it
                changed_attributes[#{name.inspect}] = #{class_name}.coerce(*args)
              end
            end
          EOM

          attribute_parent_type.class_eval <<-EOM, __FILE__, __LINE__+1
            def #{name}=(value)
              changed_attributes[#{name.inspect}] = #{class_name}.coerce(value)
            end
          EOM
        end

        #
        # Calculate the default for this attribute given the struct.
        #
        # First tries the actual value, then the default.
        #
        def get_attribute(struct)
          if struct.changed_attributes.has_key?(attribute_name)
            return struct.changed_attributes[attribute_name]
          end

          # Get the actual value first.  If we have a "load" value, call that.
          # Otherwise, call struct.actual_value
          if load
            value = struct.instance_exec(self, &load)
            if value
              struct.changed_attributes[attribute_name] = value
            end
          else
            actual_struct = struct.actual_value
            if actual_struct && actual_struct.changed_attributes.has_key?(attribute_name)
              value = actual_struct.changed_attributes[attribute_name]
            end
          end

          # If that didn't work, pull the default.
          if !value
            if default.is_a?(Proc)
              value = struct.instance_exec(self, &default)
            else
              value = default
            end
          end

          coerce(value)
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
          @attribute = value
        end

        #
        # True if this attribute is required (defaults to true).
        #
        # Required identity attributes can be specified positionally in `open`,
        # like so: `FileResource.open('/x/y.txt')` is equivalent to
        # `FileResource.open(path: '/x/y.txt')`
        #
        # This has no meaning for non-identity attributes.
        #
        def required?
          defined?(@attribute) ? @attribute : true
        end

        #
        # A block which calculates the default for a value of this type.
        #
        # Run in context of the parent struct, and is passed the Type as a
        # parameter.
        #
        # NOTE: the way it's implemented, you can't have the default for a
        #
        def default(value=NOT_PASSED, &block)
          if block
            @default = block
          elsif value == NOT_PASSED
            @default
          else
            @default = value
          end
        end
        def default=(value)
          @default = value
        end

        #
        # A block which loads the attribute
        #
        def load(value=NOT_PASSED, &block)
          if block
            @load = block
          elsif value == NOT_PASSED
            @load
          else
            @load = value
          end
        end
        def load=(value)
          @load = value
        end
      end
    end
  end
end

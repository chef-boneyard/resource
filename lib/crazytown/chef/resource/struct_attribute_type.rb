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
          struct.desired_values[attribute_name] = coerce(*args)
        end

        #
        # Get the attribute value from the struct.
        #
        # First tries to get the desired value.  If there is none, tries to get
        # the actual value from the struct.  If the actual value doesn't have
        # the value, it looks for a load_value method.  Finally, if that isn't
        # there, it runs default_value.
        #
        # TODO can load_value and default_value be the same thing?
        #
        def get_attribute(struct)
          if struct.desired_values.has_key?(attribute_name)
            return struct.desired_values[attribute_name]
          end

          # Get the actual value first.  If we have a "load" value, call that.
          # Otherwise, call struct.actual_value
          actual_struct = struct.actual_value
          if actual_struct
            if actual_struct.desired_values.has_key?(attribute_name)
              return actual_struct.desired_values[attribute_name]
            elsif load_value
              value = coerce(struct.instance_exec(self, &load_value))
              if value
                actual_struct.desired_values[attribute_name] = value
                return value
              end
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
        # A block which calculates the default for a value of this type.
        #
        # Run in context of the parent struct, and is passed the Type as a
        # parameter.
        #
        # NOTE: the way it's implemented, you can't have the default actually
        # *be* a proc.  Well, I suppose you could have a proc that returns a
        # proc ...
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
        # A block which loads the attribute from reality.
        #
        def load_value(value=NOT_PASSED, &block)
          if block
            @load_value = block
          elsif value == NOT_PASSED
            @load_value
          else
            @load_value = value
          end
        end
        def load_value=(value)
          @load_value = value
        end
      end
    end
  end
end

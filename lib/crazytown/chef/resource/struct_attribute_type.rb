require 'crazytown/chef/resource_type'

module Crazytown
  module Chef
    module Resource
      #
      # Struct attributes all create a class for each attribute.  This is
      # included in that class, and StructAttributeType is extended in that class.
      #
      module StructAttributeType
        include ResourceType

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
        # (Attributes can't use `self` because they can accept any value of the
        # given )
        #
        def implemented_by?(instance)
          attribute_type ? instance.is_a?(attribute_type) : true
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
                if open_attributes.has_key?(#{name.inspect})
                  open_attributes[#{name.inspect}]
                else
                  # Default the attribute to actual_value
                  actual_value = self.actual_value
                  actual_value = actual_value.#{name} if actual_value
                  if actual_value.frozen?
                    actual_value
                  else
                    open_attributes[#{name.inspect}] = #{class_name}.coerce(actual_value)
                  end
                end
              else
                # If we have arguments, grab the new desired value and set it
                open_attributes[#{name.inspect}] = #{class_name}.coerce(*args)
                explicitly_set_attributes << #{name.inspect}
              end
            end
          EOM

          attribute_parent_type.class_eval <<-EOM, __FILE__, __LINE__+1
            def #{name}=(value)
              open_attributes[#{name.inspect}] = #{class_name}.coerce(value)
              explicitly_set_attributes << #{name.inspect}
            end
          EOM
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
      end
    end
  end
end

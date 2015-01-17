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
                if changed_attributes.has_key?(#{name.inspect})
                  changed_attributes[#{name.inspect}]
                else
                  value = actual_value
                  if value && value.changed_attributes.has_key?(#{name.inspect})
                    value = value.changed_attributes[#{name.inspect}]
                  elsif #{class_name}.default_block
                    value = instance_exec(#{class_name}, &#{class_name}.default_block)
                  else
                    value = #{class_name}.default_value
                  end
                  #{class_name}.coerce(value)
                end
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
        # The default value for values of this type
        #
        attr_accessor :default_value

        #
        # A block which calculates the default for a value of this type.
        #
        # Run in context of the parent struct, and is passed the Type as a
        # parameter (t)
        #
        attr_accessor :default_block
      end
    end
  end
end

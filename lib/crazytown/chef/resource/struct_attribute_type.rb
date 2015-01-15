require 'crazytown/chef/resource/resource_type'

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
        # Emit attribute methods into the struct class (attribute_parent_type)
        #
        def emit_attribute_methods
          name = attribute_name
          attribute_parent_type.class_eval <<-EOM, __FILE__, __LINE__+1
            def #{attribute_name}(#{open_arguments})
              open_attributes[#{name.inspect}] = #{self.name}.get_or_set(self, #{open_argument_names.join(", ")})
            end
          EOM

          attribute_parent_type.class_eval <<-EOM, __FILE__, __LINE__+1
            def #{name}=(value)
              open_attributes[#{name.inspect}] = #{self.name}.coerce(value)
            end
          EOM
        end

        def coerce(*args, **named_args)
          if attribute_type && args.size == 1 && named_args.empty? && args[0].is_a?(attribute_type)
            args[0]
          elsif named_args.empty?
            super(*args)
          else
            super(*args, **named_args)
          end
        end

        def get_or_set(parent_struct, *open_args, **open_named_args)
          if open_args.empty? && open_named_args.empty?
            if parent_struct.open_attributes.has_key?(attribute_name)
              parent_struct.open_attributes[attribute_name]
            else
              actual_struct = parent_struct.actual_value
              value = coerce(actual_struct ? actual_struct.public_send(attribute_name) : nil)
              parent_struct.open_attributes[attribute_name] = value
            end
          else
            coerce(*open_args, **open_named_args)
          end
        end

        # def open(parent_struct)
        #   new(parent_struct)
        # end
        #
        # def get(parent_struct)
        #   open(parent_struct)
        # end
        #
        # def update(parent_struct, &define_block)
        #   if embedded_resource?
        #     result = open(parent_struct)
        #     result.instance_eval(&define_block) if define_block
        #     result.update
        #   else
        #     raise "update() not implemented on #{attribute_type || "simple attribute types"}"
        #   end
        # end

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

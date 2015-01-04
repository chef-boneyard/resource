require 'crazytown/type/type_init'
require 'crazytown/constants'
require 'crazytown/accessor/struct_attribute'
require 'crazytown/camel_case'

module Crazytown
  module Type
    #
    # Mixes into a Type to create a struct attribute.  `StructAttributeType`
    # primarily handles default values and inheritance, and emits getters and
    # setters into the Struct class.
    #
    # `StructAttributeType` is meant to be extended into a Value (or included
    # into a Type) as a mixin; it adds metadata about the declaring struct and
    # the attribute name there and can use that information to emit the getter
    # and setter methods.
    #
    # This is used by `StructType` to create new attributes.
    #
    # Usage: Creating New Attributes
    # ------------------------------
    # Creating a new attribute involves calling to_value like so:
    #
    # ```ruby
    # StructAttributeType.to_value(parent_struct_type, name, <type arguments>)
    # ```
    #
    # Where `<type arguments>` are the normal arguments you would pass to
    # `Type.to_value` or `attribute :name, <type arguments>`
    #
    # `StructAttributeType`s have `attribute_parent_type`,
    # `attribute_name` and `attribute_readonly` properties.
    #
    # With `attribute`:
    # ```ruby
    # class MyStruct < StructBase
    #   attribute :foo, Hash, original_value: { a: 1, b: 2, c: 3 }
    # end
    # MyStruct.new.foo == { a: 1, b: 2, c: 3 }
    # ```
    #
    # With `StructAttributeType.to_value`:
    # ```ruby
    # class MyStruct < StructBase
    #   attributes[:foo] = StructAttributeType.to_value(Hash, original_value: { a: 2, b: 2, c: 3 })
    # end
    # MyStruct.new.foo == { a: 1, b: 2, c: 3 }
    # ```
    # Raw usage:
    # ```ruby
    # class MyStruct < StructBase
    #   class Foo < Crazytown::Hash
    #     extend StructAttributeType
    #     attribute_parent_type MyStruct
    #     attribute_name :foo
    #     original_value a: 1, b: 2, c: 3
    #   end
    #   attributes[:foo] = Foo
    #   Foo.emit_getter_setter
    # end
    # MyStruct.new.foo == { a: 1, b: 2, c: 3 }
    # ```
    #
    # What It Really Looks Like
    # -------------------------
    # After using `attribute :foo, Hash, { original_value a: 1, b: 2, c: 3 }`,
    # the class is exactly equivalent to:
    #
    # ```ruby
    # class MyStruct < StructBase
    #   # Define the attribute type (Hash named foo with an initial value)
    #   class Foo < Crazytown::Hash
    #     extend StructAttributeType
    #     attribute_parent_type MyStruct
    #     attribute_name :foo
    #     original_value a: 1, b: 2, c: 3
    #   end
    #   def foo(*args, &block)
    #     if args.size == 0 && !block
    #       Foo.get_attribute(self)
    #     else
    #       Foo.set_attribute(self)
    #     end
    #   end
    # end
    # ```
    #
    # `get_attribute` and `set_attribute` look up `struct_raw_hash` for the
    # attribute's key.
    #
    # Overriding Attributes
    # ---------------------
    # Overriding attributes can be done with `specialize` on the
    # `StructAttributeType`:
    #
    # ```ruby
    # class Foo < StructBase
    #   attribute :a, Hash { key_type: Symbol }
    # end
    # class Bar < Foo
    #   attributes[:a] = attributes[:a].specialize { value_type: Fixnum, original_value a: 2 }
    # end
    # Bar.new.a[1] = 10 # fails due to key_type
    # Bar.new.a[:b] = :hi # fails due to value_type
    # ```
    #
    module StructAttributeType
      extend TypeType
      value_module Accessor::StructAttribute
#        include AccessorType

      #
      # interface for an AttributeType: helpers to get, set, check and reset attributes
      #
      def get_attribute(parent)
        fetched = parent.struct_raw_hash.fetch(name) { return original_value }
        from_value(fetched)
      end
      def set_attribute(parent, *args, &block)
        parent.struct_raw_hash.store(name, to_value(*args, &block))
      end
      def attribute_set?(hash)
        hash.has_key?(name)
      end
      def reset_attribute(hash)
        result = true
        hash.delete(name) { result = false }
        result
      end

      def emit_getter_setter(parent_type=nil, name=nil)
        parent_type ||= attribute_parent_type
        name ||= attribute_name

        class_name = CamelCase.from_snake_case(attribute_name)

        parent_type.const_set(class_name, self)

        if attribute_readonly
          parent_type.class_eval <<-EOM, __FILE__, __LINE__+1
            def #{name}(*args, &block)
              #{class_name}.get_attribute(self)
            end
            undef_method(:#{name}=) if method_defined?(:#{name}=)
          EOM
        else
          parent_type.class_eval <<-EOM, __FILE__, __LINE__+1
            def #{name}(*args, &block)
              puts "#{name} \#{args.inspect} &\#{block}"
              if args.size == 0 && !block
                #{class_name}.get_attribute(self)
              else
                #{class_name}.set_attribute(self, *args, &block)
              end
            end
            def #{name}=(value)
              #{class_name}.set_attribute(self, value)
            end
          EOM
        end
      end

      def to_s
        "#{attribute_parent_type}.#{attribute_name}"
      end

      #
      # Create a new StructAttributeType.
      #
      # TODO if existing type is not passed, specialize parent attribute type
      # instead of creating a new one.
      def self.to_value(parent_type, name, *args, &override)
        Type.to_value(*args) do
          extend StructAttributeType
          attribute_parent_type parent_type
          attribute_name name
          instance_eval(&override) if override
          emit_getter_setter
        end
      end

      TypeInit.bootstrap_type_system

      require 'crazytown/boolean'
      attribute :attribute_name, Symbol
      attribute :attribute_parent_type, StructType
      attribute :attribute_readonly, Boolean
    end
  end
end

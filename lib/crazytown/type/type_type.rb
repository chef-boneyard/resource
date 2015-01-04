# Used in Value, Struct, Type, StructType and TypeType to resolve circles
require 'crazytown/type/type_init'

module Crazytown
  module Type
    #
    # The Type used to *define* other Types.  If you want something that is a
    # Type, you use TypeType.to_value.
    #
    # TypeType has `value_module` in it.  If `FooType` extends `TypeType`, it will:
    #
    # ```ruby
    # module FooType
    #   extend TypeType
    #   value_module Foo
    # end
    # Foo <= FooType == true
    # ```
    #
    # This will cause `FooType` to:
    # - include `Type`
    # - cause other modules and classes to include `Foo` when they extend `FooType`:
    #
    # ```ruby
    # class Bar
    #   extend FooType
    # end
    # Bar <= FooType == true
    # ```
    #
    module TypeType
      include StructType
      extend TypeType
      value_module Type

      #
      # When MyType.value_module = MyValue, two things happen:
      #
      # ```ruby
      # module MyValue
      #   extend MyType
      # end
      # module MyType
      #   def self.extended(other)
      #     other.send(:include, MyValue)
      #   end
      # end
      # ```
      #
      def value_module(value_module)
        value_module.extend(self)
        define_singleton_method(:extended) do |other|
          other.send(:include, value_module) if value_module != other
        end
      end

      def value_class(value_class)
        value_class.extend(self)
      end

      #
      # Create a new Struct value.
      #
      # @param struct_class A type (class) to override.  `self.class.new(struct_class)` will be called.
      # @param override A block passed in the context of the new Struct class.
      #
      def to_value(other_type=nil, *args, &override)
        if other_type.is_a?(Class)
          other_type.specialize(*args) do
            extend self
            instance_eval(&override) if override
          end
        elsif self.is_a?(Class)
          Class.new(self) do
            extend other_type if other_type
            instance_eval(&override) if override
          end
        else
          Module.new do
            extend self
            extend other_type if other_type
            instance_eval(&override)
          end
        end
      end

      require 'crazytown/type'
      require 'crazytown/type/struct_type'
    end
  end
end

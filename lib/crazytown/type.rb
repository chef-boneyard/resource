# Used in Value, Struct, Type, StructType and TypeType to resolve circles
require 'crazytown/type/type_init'

module Crazytown
  #
  # All Types are assumed to be modules or classes.
  #
  module Type
    include Value
    extend TypeType
    value_module Value

    #
    # Convert user input to a raw, storable value.  This allows for input validation
    # as well as coercion.
    #
    # Subclasses may implement any number of parameters, and even blocks; this
    # method is suitable for customization.
    #
    def to_value(value)
      value
    end

    #
    # Convert this value from its raw internal format to something the user expects.
    #
    def from_value(raw)
      raw
    end

    #
    # Specialize this type.
    #
    def specialize(&override)
      if self.is_a?(Class)
        Class.new(self, &override)
      else
        this_type = self
        Module.new do
          include this_type
          instance_eval(&override) if override
        end
      end
    end

    #
    # Type.to_value is our catch-all method to easily create new Types.
    #
    def self.to_value(instance_type=NOT_PASSED, *args, &override)
      if instance_type == NOT_PASSED
        return super(&override)
      end

      case instance_type
      when ::Hash
        # to_value(Hash[Symbol => String])
        key, value = instance_type.first
        HashType.to_value(*args) do
          include other_type if other_type != self
          key_type key
          value_type value
          instance_eval(&override) if override
        end

      when ::Array
        # eg. to_value(Array[String])
        ArrayType.to_value(*args) do
          include other_type if other_type != self
          element_type array.first
          instance_eval(&override) if override
        end

      when ::Set
        # e.g. to_value(Set[Symbol])
        SetType.to_value(*args) do
          include other_type if other_type != self
          item_type instance_type.first
          instance_eval(&override) if override
        end

      when Type
        # TypeType.to_value
        super

      when Class
        if instance_type == Symbol
          super(Value) do
            def to_value(value)
              value.to_sym
            end
          end
        elsif instance_type == Boolean
          Type::BooleanType.specialize(*args, &override)
        else
          # TypeType.to_value
          super(Value) do
            const_set(:ValidationIsA, instance_type)
            def to_value(value)
              value = super
              if !value.is_a?(ValidationIsA)
                raise ValidationError, "#{value} must be a #{IsA}!"
              end
              value
            end
            instance_eval(&override) if override
          end
        end

      when nil
        to_value(Value, *args, &override)

      else
        raise "Unknown type #{instance_type} passed to Type constructor!"
      end
    end

    TypeInit.bootstrap_type_system

    require 'crazytown/value'
    require 'crazytown/boolean'
    require 'crazytown/type/type_type'
    require 'crazytown/type/symbol_type'
    require 'crazytown/type/boolean_type'
    require 'crazytown/type/struct_type'
    require 'crazytown/type/hash_type'

    #
    # Initial value for values of this type.  The initial value is not stored
    # in the value itself, but instead queried for when needed.
    #
    attribute :original_value do
      def get_attribute(parent_type, *args, &block)
        parent_type.from_value(super)
      end
      def set_attribute(parent_type, *args, &block)
        super(parent_type, parent_type.to_value(*args, &block))
      end
    end

    def lazy_original_value(&block)
      parent_type = self
      attributes[:original_value] = attributes[:original_value].specialize do
        attribute_parent_type parent_type
        attribute_readonly true
        def get_attribute(parent_type)
          raise "lazy_original_value cannot be retrieved from the type!  ask for #{InitialValue.name}.get_original_value(value) instead."
        end
        define_method(:get_original_value) do |parent|
          parent.class.to_value(parent.instance_eval(&block))
        end
      end
    end
  end
end

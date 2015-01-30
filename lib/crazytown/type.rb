require 'crazytown/errors'
require 'crazytown/simple_struct'

module Crazytown
  module Type
    extend SimpleStruct

    #
    # Take the input value and coerce it to a desired value (which means
    # different things in different contexts).  For a Resource Reference,
    # this will return a non-open Resource.  For a primitive, it casts the
    # value to the right type.
    #
    # @return A value which:
    # - Implements the desired type
    # - May or may not be open (depends on whether it's a reference or not)
    # - May have any and all values set (not just identity values, unlike get)
    #
    def coerce(value)
      validate(value)
      value
    end

    #
    # Returns whether the given value could have been returned by a call to
    # `coerce`, `open` or `get`.
    #
    def is_valid?(instance)
      begin
        validate(instance)
        true
      rescue ValidationError
        false
      end
    end

    #
    # Validates a value against this type.
    #
    # TODO perhaps autogenerate this in subclasses
    # TODO toss ALL validation errors, not just the one!
    #
    def validate(value)
      # Handle nullable=true/false
      if value.nil? && !nullable.nil?
        if nullable?
          # If nullable is true, we don't run any other validation.
          return
        else
          raise ValidationError.new("must not be null", value)
        end
      end

      # Check must_be_kind_of
      if value && !must_be_kind_of.empty? && !must_be_kind_of.any? { |type| value.is_a?(type) }
        raise ValidationError.new("must be a #{Crazytown.english_list('or', *must_be_kind_of)}", value)
      end

      validators.each do |message, must_be_true|
        if !value.instance_exec(self, &must_be_true)
          raise ValidationError.new(message, value)
        end
      end
    end

    #
    # Adds a validation rule to this class that must always be true.
    #
    # @param message The failure message (will be prefaced with "must")
    # @param &must_be_true Validation block, called in the context of the
    #   value (self == value), with two parameters: (type, parent), where
    #   parent is the parent value (if any) and type is the type "must" was
    #   declared on.
    #
    # @example
    # class MyStruct < StructResource
    #   attribute :x, Integer do
    #     must "be between 0 and 10" { self >= 0 && self <= 10 }
    #   end
    # end
    #
    def must(description, &must_be_true)
      validators << [ "must #{description}", must_be_true ]
    end

    #
    # Whether or not this type accepts nil values.
    #
    # @param nullable If passed, this sets the value.
    # - If true, validation always succeeds on nil values (and validators are not run).
    # - If false, validation fails on nil values.
    # - If nil, validation is run on nil values like normal.
    #
    # Defaults to true.
    #
    boolean_attribute :nullable, default: "true"

    #
    # A set of validators that will be run.  An array of pairs [ message, proc ],
    # where validate will run each `proc`, and throw `message` if it returns nil
    # or false.
    #
    def validators
      @validators ||= begin
        if is_a?(Class) && superclass && superclass.respond_to?(:validators)
          superclass.validators.dup
        else
          []
        end
      end
    end

    #
    # An array of classes or modules which values of this type must implement
    # (`value.kind_of?(class_or_module)` must be true).
    #
    # @param classes_or_modules If passed, this will *set* the list of classes
    #   or modules (or a single class or module) which values of this type
    #   must implement.
    #
    attribute :must_be_kind_of
    alias :orig_must_be_kind_of :must_be_kind_of

    def must_be_kind_of(*classes_or_modules)
      case classes_or_modules.size
      when 0
        @must_be_kind_of ||= (orig_must_be_kind_of || []).dup
      when 1
        orig_must_be_kind_of(classes_or_modules[0].is_a?(Array) ? classes_or_modules[0] : classes_or_modules)
      else
        orig_must_be_kind_of(classes_or_modules)
      end
    end

    #
    # Turn the value into a string in just the context of this Type.
    #
    def value_to_s(value)
      value.to_s
    end

    #
    # Create a type class for the given type.
    #
    # #get_type will be called to get the parent type information before the
    # Type is created.
    #
    # @param name The snake case name for the type.
    # @param type [Class,Type,Symbol] If a Class, sets `instance_class`.
    #   If a Type, sets `type_class`.
    #   If a `Symbol`, looks up the constant with the given name (translated from
    #   snake_case to CamelCase), and sets either `instance_class` or
    #   `type_class` if the symbol exists.
    # @param create_class [Boolean] If true, will create a Class instead of
    #   a Module.
    # @param instance_class [Class] If passed, the resulting Type will ensure that
    #   values are restricted to instances of the class.  May also add some default
    #   coercion (for example, `Integer` subclasses call `to_i` and `Numeric`
    #   subclasses call `to_f`).  Generally, `get_type`
    # @param type_class [Type] If passed, the
    #
    def type(name,
            type=nil,
            instance_class:  NOT_PASSED,
            type_class:      NOT_PASSED,
            create_class:    nil,
            superclass:      nil,
            **type_properties,
            &override_block
            )
      # Get the actual Type class (user may have passed a Symbol or non-type Class)
      type_class = get_type(type, instance_class: instance_class, type_class: type_class)
      # Create the actual Type class (not filled in)
      result = emit_type_class(name, type_class, superclass, create_class)
      result.must_be_kind_of instance_class if instance_class != NOT_PASSED

      # Set other properties
      type_properties.each do |name, value|
        if result.respond_to?(name)
          result.public_send(name, value)
        else
          raise ArgumentError, "#{name} not supported by type #{type_class}!"
        end
      end

      if override_block
        result.class_eval(&override_block)
      end
      result
    end

    #
    # Create the type class
    #
    # @param name The name of the class to create.  Will be converted from
    #   `snake_case` to `CamelCase` before creation.
    # @param type_class The type class of which
    #
    def emit_type_class(name, type_class, superclass, create_class)
      #
      # Emit the class
      #
      class_name = CamelCase.from_snake_case(name)

      #
      # Translate create_class: true/false to Class/Module (leave nil alone)
      #
      case create_class
      when true
        create_class = Class
      when false
        create_class = Module
      end

      #
      # If the type_class is a Class, use it as the superclass of our new thing
      #
      if type_class && type_class.is_a?(Class)
        if superclass
          raise "Cannot declare a superclass for #{name}: #{type_class} is a class and will be used as the superclass!"
        end
        superclass = type_class
        type_class = nil
      end

      #
      # If we have a superclass, and `create_class` was not declared, create a class instead of a module
      #
      if superclass
        if create_class.nil?
          create_class = Class
        elsif !(create_class <= Class)
          raise "Cannot have superclass #{superclass} for #{name}: #{create_class} is not a class and cannot have a superclass!"
        end
      end

      # Default to creating a Module
      create_class ||= Module
      type_class ||= Type

      result = superclass ? create_class.new(superclass) : create_class.new
      eval "self::#{class_name} = result", nil, __FILE__, __LINE__

      result.extend type_class if !result.is_a?(type_class)
      result
    end

    #
    # Get the existing type class for the given type (or `nil` if there is none).
    #
    # @param type [Symbol]
    # @param instance_class [Class]
    # @return The existing type class for the given type.  If none, returns `nil`.
    #
    # @example Symbols
    #   type(:boolean) #=> Crazytown::Type::Boolean
    #   type(:rational) #=> Crazytown::Type::NumericType
    #   type(:my_resource) #=> MyResource
    # @example Primitive types
    #   type(Fixnum) #=> Crazytown::Type::IntegerType
    #   type(Rational) #=> Crazytown::Type::NumericType
    #   type(Hash) #=> nil
    # @example Actual type class
    #   type(Blah) #=> Blah
    #
    def get_type(type=nil, instance_class: NOT_PASSED, type_class: NOT_PASSED, &override_block)
      type = const_get(CamelCase.from_snake_case(type)) if type.is_a?(Symbol)

      case type
      when Type
        type_class = type
      when Class
        instance_class = type
      when nil
      else
        raise ArgumentError, "Cannot resolve type #{type}: class #{type.class} not recognized"
      end

      if instance_class != NOT_PASSED
        type_class = get_type_for_class(instance_class)
      elsif type_class == NOT_PASSED
        type_class = nil
      end

      type_class
    end

    #
    # Get the Type that should manage instances of the given class.
    #
    def get_type_for_class(instance_class)
      if instance_class    <= Integer
        IntegerType

      elsif instance_class <= Float
        FloatType

      elsif instance_class <= URI
        URIType

      elsif instance_class <= Pathname
        Path

      elsif instance_class <= DateTime
        DateTimeType

      elsif instance_class <= Date
        DateType

      elsif instance_class <= Symbol
        SymbolType

      elsif instance_class <= String
        StringType

      else
        nil
      end
    end
  end

  require 'crazytown/type/boolean'
  require 'crazytown/type/interval'
  require 'crazytown/type/byte_size'
  require 'crazytown/type/path'

  require 'crazytown/type/integer_type'
  require 'crazytown/type/float_type'
  require 'crazytown/type/uri_type'
  require 'crazytown/type/date_time_type'
  require 'crazytown/type/date_type'
  require 'crazytown/type/symbol_type'
  require 'crazytown/type/string_type'
end

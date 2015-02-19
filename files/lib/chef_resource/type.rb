require 'chef_resource/errors'
require 'chef_resource/simple_struct'
require 'chef_resource/lazy_proc'

module ChefResource
  module Type
    extend SimpleStruct

    #
    # Take the input value and coerce it to a desired value (which means
    # different things in different contexts).  For a Resource Reference,
    # this will return a non-open Resource.  For a primitive, it casts the
    # value to the right type.
    #
    # @param parent The parent context which is asking for the value
    #    (for a struct, the parent is the struct)
    #
    # @return A value which:
    # - Implements the desired type
    # - May or may not be open (depends on whether it's a reference or not)
    # - May have any and all values set (not just identity values, unlike get)
    #
    def coerce(parent, value)
      validate(parent, value)
      value
    end

    #
    # Take the raw (stored) value and coerce it to a value (used when the user
    # asks for a property or other value).  The default implementation simply
    # delazifies the value (and coerces/validates it if it is lazy).
    #
    # @return A value which:
    # - Implements the desired type
    # - May or may not be open (depends on whether it's a reference or not)
    # - May have any and all values set (not just identity values, unlike get)
    #
    def coerce_to_user(parent, value)
      if value.is_a?(ChefResource::LazyProc)
        coerce(parent, value.get(instance: parent))
      else
        value
      end
    end

    #
    # Returns whether the given value could have been returned by a call to
    # `coerce`, `open` or `get`.
    #
    def is_valid?(parent, value)
      begin
        validate(parent, value)
        true
      rescue ValidationError
        false
      end
    end

    #
    # Validates a value against this type.
    #
    def validate(parent, value)
      # Handle nullable=true/false
      if value.nil?
        if nullable?
          # It's OK for the value to be nulalble, so return.
          # (Unless nullable? == :validate, in which case we
          # continue to run validations.)
          return unless nullable? == :validate
        else
          # TODO error message sucks.  Needs to include property name.  Start
          # passing parent and self in, and have common methods to print out what
          # thing needs to not be null.
          # If the value is null and isn't supposed to be, raise an error
          raise MustNotBeNullError.new("must not be null", value)
        end
      end

      # Check must_be_kind_of
      if value && !must_be_kind_of.empty? && !must_be_kind_of.any? { |type| value.is_a?(type) }
        raise ValidationError.new("must be a #{ChefResource.english_list(*must_be_kind_of, conjunction: 'or')}", value)
      end

      validators.each do |message, must_be_true|
        if !must_be_true.get(instance: value, args: [parent])
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
    #   property :x, Integer do
    #     must "be between 0 and 10" { self >= 0 && self <= 10 }
    #   end
    # end
    #
    def must(description, must_be_true_block=nil, &must_be_true)
      must_be_true_block ||= must_be_true
      must_be_true_block = LazyProc.new(:should_instance_eval, &must_be_true_block) if !must_be_true_block.is_a?(LazyProc)
      validators << [ "must #{description}", must_be_true_block ]
    end

    #
    # Whether or not this type accepts nil values.
    #
    # @param nullable If passed, this sets the value.
    # - If true, validation always succeeds on nil values (and validators are not run).
    # - If false, validation fails on nil values.
    # - If :validate, validation is run on nil values like normal.
    #
    # Defaults to false unless the value has a `nil` default, in which case it is `true`.
    #
    # TODO this is wrong: @default does not take into account superclasses
    boolean_property :nullable, default: "defined?(@default) && @default.nil?"

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
    property :must_be_kind_of, default: "[]"

    def must_be_kind_of(*classes_or_modules)
      case classes_or_modules.size
      when 0
        @must_be_kind_of ||= super.dup
      when 1
        super(classes_or_modules[0].is_a?(Array) ? classes_or_modules[0] : classes_or_modules)
      else
        super(classes_or_modules)
      end
    end

    #
    # The default value for things of this type.
    #
    # @param value The default value.  If this is a LazyProc, the block will
    #   be run in the context of the struct (`struct.instance_eval`) unless
    #   the block is explicitly set to `should_instance_eval: false`.  If `nil`, the
    #   type is assumed to be nullable.
    #
    property :default, coerced: "coerce(parent, value)", coerced_set: "value.nil? ? value : coerce(parent, value)"

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
    #   type(:boolean) #=> ChefResource::Types::Boolean
    #   type(:rational) #=> ChefResource::Types::NumericType
    #   type(:my_resource) #=> MyResource
    # @example Primitive types
    #   type(Fixnum) #=> ChefResource::Types::IntegerType
    #   type(Rational) #=> ChefResource::Types::NumericType
    #   type(Hash) #=> nil
    # @example Actual type class
    #   type(Blah) #=> Blah
    #
    def get_type(type=nil, instance_class: NOT_PASSED, type_class: NOT_PASSED, &override_block)
      type = const_get(CamelCase.from_snake_case(type)) if type.is_a?(Symbol)

      case type
      when Type
        type_class = type
      when Module
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
        Types::IntegerType

      elsif instance_class <= Float
        Types::FloatType

      elsif instance_class <= URI
        Types::URIType

      elsif instance_class <= Pathname
        Types::PathnameType

      elsif instance_class <= DateTime
        Types::DateTimeType

      elsif instance_class <= Date
        Types::DateType

      elsif instance_class <= Symbol
        Types::SymbolType

      elsif instance_class <= String
        Types::StringType

      else
        nil
      end
    end
  end

  require 'chef_resource/types/boolean'
  require 'chef_resource/types/interval'
  require 'chef_resource/types/byte_size'
  require 'chef_resource/types/path'

  require 'chef_resource/types/integer_type'
  require 'chef_resource/types/float_type'
  require 'chef_resource/types/uri_type'
  require 'chef_resource/types/date_time_type'
  require 'chef_resource/types/date_type'
  require 'chef_resource/types/symbol_type'
  require 'chef_resource/types/string_type'
end

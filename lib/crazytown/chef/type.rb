require 'crazytown/errors'

module Crazytown
  module Chef
    module Type
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
        if value && !must_be_kind_of.any? { |type| value.is_a?(type) }
          case must_be_kind_of.size
          when 0
          when 1
            raise ValidationError.new("must be a #{must_be_kind_of[0]}", value)
          else
            raise ValidationError.new("must be a #{must_be_kind_of[0..-2].join(", ")} or #{must_be_kind_of[-1]}", value)
          end
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
      #   attribute :x, Fixnum do
      #     must "be between 0 and 10" { self >= 0 && self <= 10 }
      #   end
      # end
      #
      def must(description, &must_be_true)
        validators << [ "must #{description}", must_be_true ]
      end

      #
      # Set whether or not this type accepts nil values.
      #
      # @param nullable The new value
      #   - If true, validation is not run on the value.
      #   - If false, validation fails on nil values.
      #   - If nil, validation is run on nil values like normal.
      #
      def nullable=(nullable)
        @nullable = nullable
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
      def nullable(nullable=NOT_PASSED)
        if nullable == NOT_PASSED
          defined?(@nullable) ? @nullable : true
        else
          @nullable = nullable
        end
      end

      #
      # Whether or not this type accepts nil values.
      #
      def nullable?
        nullable
      end

      #
      # A set of validators that will be run.  An array of pairs [ message, proc ],
      # where validate will run each `proc`, and throw `message` if it returns nil
      # or false.
      #
      def validators
        @validators ||= []
      end

      #
      # Set an array of classes or modules which values of this type must
      # implement (`value.kind_of?(class_or_module)` must be true).
      #
      # @param classes_or_modules A list of classes or modules (or a single
      #   class or module) which values of this type must implement.
      #
      def must_be_kind_of=(classes_or_modules)
        @must_be_kind_of = classes_or_modules.is_a?(Array) ? classes_or_modules : [ classes_or_modules ]
      end

      #
      # An array of classes or modules which values of this type must implement
      # (`value.kind_of?(class_or_module)` must be true).
      #
      # @param classes_or_modules If passed, this will *set* the list of classes
      #   or modules (or a single class or module) which values of this type
      #   must implement.
      #
      def must_be_kind_of(classes_or_modules=NOT_PASSED)
        if classes_or_modules == NOT_PASSED
          @must_be_kind_of ||= []
        else
          @must_be_kind_of = classes_or_modules.is_a?(Array) ? classes_or_modules : [ classes_or_modules ]
        end
      end
    end
  end
end

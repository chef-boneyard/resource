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
        if implemented_by?(value)
          value
        else
          raise ValidationError, "#{value} is not the right type to be coerced by #{self.class}"
        end
      end

      #
      # Returns whether the given value could have been returned by a call to
      # `coerce`, `open` or `get`.
      #
      # TODO this could be a validation thing too, perhaps
      #
      def implemented_by?(instance)
        instance.is_a?(self) || instance.nil?
      end

      #
      # The default value for instances of this type
      #
      attr_accessor :default_value
    end
  end
end

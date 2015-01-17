module Crazytown
  module Chef
    module Resource
      #
      # The methods on a Resource class.  Generally extended into the class, and
      # become class-level methods (Class.default_value(x))
      #
      module ResourceType
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
            raise ArgumentError, "#{value} is not the right type to be coerced by #{self.class}"
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
        # Opens a resource for reading and updating.
        #
        # This method should be passed enough data to uniquely identify the
        # resource so it can be retrieved.
        #
        # The resulting object is generally *lazily* loaded, and may not hit the
        # network or file until you read a value.  This allows you to update
        # values in some cases without incurring the cost of a read.
        #
        # @return An open Resource which:
        # - `self.implemented_by?(resource)` is true
        # - Is a Resource
        # - Is a Resource even if the actual value does not exist
        # - Can be modified for update
        #
        def open
          new
        end

        #
        # Gets the current value of a resource (immediately).  This method must
        # be passed enough data to uniquely identify the resource so it can be
        # retrieved.
        #
        # The default implementation (ResourceType.get) calls open(), load(),
        # and sets exists to true if load succeeds and does not set exists
        # explicitly.
        #
        # @return A resource value with values immediately filled in; or nil
        #   if the resource does not exist.
        #
        def get(*args)
          #
          # This code is identical to Resource.actual_value, except it uses
          # open(*args) instead of reopen.
          #
          resource = open(*args)
          # The resource we use for our actual_value, *shall not have its own*
          # actual_value.  That way lies madness.  We do not truck with madness.
          resource.actual_value = nil
          resource.load
          # Foolproofing: if the user does not set exists, assume a successful
          # `load` means it *does* exist.  Principle of Least Surprise.
          resource.exists = true if !result.exists_is_set?
          resource.exists? ? result : nil
        end

        #
        # Updates a resource.  By default, opens the resource, evaluates the
        # block, and calls update().
        #
        # @param open_args Arguments to pass to open()
        # @param update_block The block to run instance_eval on.
        #
        # @example
        #   FileResource.update('/x/y.txt') do
        #     mode 0777
        #   end
        #
        def update(*open_args, &update_block)
          resource = open(*args)
          resource.instance_eval(&update_block)
          resource.update
        end
      end
    end
  end
end

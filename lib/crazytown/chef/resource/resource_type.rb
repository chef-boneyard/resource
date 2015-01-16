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
          value
        end

        #
        # Opens a resource for updating.  This method should be passed enough
        # data to uniquely identify the resource so it can be retrieved.
        #
        # The default implementation (ResourceType.open) just assumes the
        # ResourceType is a class, and calls new() with no parameters.
        #
        # @return An open Resource which:
        # - Implements the desired type
        # - Is a Resource
        # - Is a Resource even if the actual value does not exist
        # - Can be modified for update
        #
        def open
          new
        end

        #
        # Get the value for the resource (which may be readonly).  Subclasses
        # may pass any parameters they wish.
        #
        # @return A value which:
        # - Implements the desired type
        # - May be readonly
        # - Is *not* an open Resource, even if it is a Resource
        #
        def get(*args)
          open(*args)
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

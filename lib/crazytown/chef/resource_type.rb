require 'crazytown/chef/type'

module Crazytown
  module Chef
    module Resource
      #
      # The methods on a Resource class.  Generally extended into the class, and
      # become class-level methods (Class.default_value(x))
      #
      module ResourceType
        include Type

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

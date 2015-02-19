require 'chef_resource/type'

module ChefResource
  module Resource
    #
    # The methods on a Resource class.  Generally extended into the class, and
    # become class-level methods (Class.default(x))
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
      # - Is a Resource
      # - Is a Resource even if the actual value does not exist
      # - Can be modified for update
      # - `type.is_valid?(resource, resource)` is true
      #
      def open(&define_identity_block)
        resource = new
        resource.instance_eval(&define_identity_block)
        resource.resource_identity_defined if resource.resource_state == :created
        resource
      end

      #
      # Gets the current value of a resource (immediately).  This method must
      # be passed enough data to uniquely identify the resource so it can be
      # retrieved.
      #
      # The default implementation (ResourceType.get) calls open(*args) { load }
      #
      # @return A readonly resource value with values filled in; or nil if the
      # resource does not exist.
      #
      def get(*args, &define_identity_block)
        resource = open(*args) do
          instance_eval(&define_identity_block) if define_identity_block
          load
        end
        resource.resource_fully_defined
        resource
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
        resource.resource_fully_defined
        resource.update_resource
      end
    end
  end
end
